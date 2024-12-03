#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <elf.h>
#include <common.h>
#include <utils.h>
#include <cpu/ftrace.h>

function_info *functions = NULL;
int function_num = 0;
int ftrace_tab_size = 0;

#define BUFFER_SIZE 1024 * 1024 // 1MB 缓冲区
char output_buffer[BUFFER_SIZE];
size_t buffer_offset = 0;
extern FILE* log_fp;

void ftrace_printf(const char *format, ...) {
    va_list args;
    va_start(args, format);
    int written = vsnprintf(output_buffer + buffer_offset, BUFFER_SIZE - buffer_offset, format, args);
    va_end(args);
    buffer_offset += written;
}

void ftrace_log() {
    if(log_fp == NULL) {
        printf("%s",output_buffer);
    }else{
        log_write("%s", output_buffer);
    }
    
}

void init_elf(const char *elf_file) {
    printf("elf_file = %s\n", elf_file);
    if (elf_file != NULL) {
        FILE *fp = fopen(elf_file, "rb");
        Assert(fp, "Can not open '%s'", elf_file);

#if defined(CONFIG_ISA_riscv) && !defined(CONFIG_RV64)
        Elf32_Ehdr ehdr;
        if(fread(&ehdr, 1, sizeof(ehdr), fp) != sizeof(ehdr)) {
        Assert(fp, "Failed to read ELF header");
        }

        if (memcmp(ehdr.e_ident, ELFMAG, SELFMAG) != 0) {
        Assert(fp, "Invalid ELF magic");
        }

        fseek(fp, ehdr.e_shoff, SEEK_SET);

        Elf32_Shdr shdr, shdr_symtab, shdr_strtab;
        Elf32_Sym sym;

        Elf32_Half i;
        // find the symbol table
        for (i = 0; i < ehdr.e_shnum; i++) {
        if(fread(&shdr, 1, sizeof(shdr), fp) != sizeof(shdr)) {
            Assert(fp, "Failed to read ELF section header");
        }
        if (shdr.sh_type == SHT_SYMTAB) {
            shdr_symtab = shdr;
            break;
        }
        }

        if(i == ehdr.e_shnum) {
        Assert(fp, "Failed to find ELF symbol table");
        }

        // find the corresponding string table
        fseek(fp, ehdr.e_shoff + ehdr.e_shentsize * shdr_symtab.sh_link, SEEK_SET);
        if(fread(&shdr_strtab, 1, sizeof(shdr_strtab), fp) != sizeof(shdr_strtab)) {
        Assert(fp, "Failed to find ELF string table");
        }

        //  get the string table
        char *strtab;
        fseek(fp, shdr_strtab.sh_offset, SEEK_SET);
        strtab = malloc(shdr_strtab.sh_size); 
        if(fread(strtab, 1, shdr_strtab.sh_size, fp) != shdr_strtab.sh_size) {
            Assert(fp, "Failed to read ELF string table");
        }

        fseek(fp, shdr_symtab.sh_offset, SEEK_SET);
        function_num = 0;
        for (int j = 0; j < shdr_symtab.sh_size / shdr_symtab.sh_entsize; j++) {
            if(fread(&sym, 1, sizeof(sym), fp) != sizeof(sym)) {
                Assert(fp, "Failed to read ELF symbol");
            }
            if (ELF32_ST_TYPE(sym.st_info) == STT_FUNC) {
                function_info *ret;
                ret = realloc(functions, sizeof(function_info) * (function_num + 1));
                if(ret == NULL) {
                    Assert(fp, "Failed to realloc memory for function info");
                }
                functions = ret;
                functions[function_num].start = sym.st_value;
                functions[function_num].size = sym.st_size;
                strncpy(functions[function_num].name, &strtab[sym.st_name], 31);
                functions[function_num].name[31] = '\0';

                // printf("num %d, function name: %s, address = 0x%08x, size = %d.\n", function_num, functions[function_num].name, functions[function_num].start, functions[function_num].size);
                function_num ++;
            }
        }
        free(strtab);
        fclose(fp);
#endif
    }
    return;
}

void ftrace_call(vaddr_t pc, vaddr_t next_pc) {
    ftrace_printf(FMT_WORD ": ", pc);
    for (int i = 0; i < function_num; i++) {
        if (next_pc == functions[i].start) {
            for(int j = 0; j < ftrace_tab_size; j++) {
                ftrace_printf("  ");
            }
            ftrace_tab_size ++;
            ftrace_printf("call [%s@" FMT_WORD "]\n", functions[i].name, next_pc);
            break;
        }
    }
    return;
}

void ftrace_ret(vaddr_t pc) {
    ftrace_printf(FMT_WORD ": ", pc);
    for (int i = 0; i < function_num; i++) {
        if (pc >= functions[i].start && pc < functions[i].start + functions[i].size) {
            ftrace_tab_size --;
            for(int j = 0; j < ftrace_tab_size; j++) {
                ftrace_printf("  ");
            }
            ftrace_printf("ret [%s]\n", functions[i].name);
            break;
        }
    }
    return;
}