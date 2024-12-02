#include <stdio.h>
#include <string.h>
#include <elf.h>
#include <common.h>
#include <cpu/ftrace.h>

void init_elf(const char *elf_file) {
    printf("elf_file = %s\n", elf_file);
    if (elf_file != NULL) {
        FILE *fp = fopen(elf_file, "rb");
        Assert(fp, "Can not open '%s'", elf_file);

// #if defined(CONFIG_ISA_riscv) && !defined(CONFIG_RV64)
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
        char *strtab;

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
        fseek(fp, shdr_strtab.sh_offset, SEEK_SET);
        strtab = malloc(shdr_strtab.sh_size); 

        fseek(fp, shdr_symtab.sh_offset, SEEK_SET);
        for (int j = 0; j < shdr_symtab.sh_size / shdr_symtab.sh_entsize; j++) {
            if(fread(&sym, 1, sizeof(sym), fp) != sizeof(sym)) {
                Assert(fp, "Failed to read ELF symbol");
            }
            if (ELF32_ST_TYPE(sym.st_info) == STT_FUNC) {
                printf("function name: %c\n", strtab[sym.st_name]);
            }
        }
// #endif
  }
  return;
}