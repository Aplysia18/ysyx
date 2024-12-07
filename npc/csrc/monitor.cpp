#include "monitor.hpp"

static char *img_file = NULL;

static long load_img() {
  if (img_file == NULL) {
    // Log("No image is given. Use the default build-in image.");
    printf("No image is given. Use the default build-in image.\n");
    return 4096; // built-in image size
  }

  FILE *fp = fopen(img_file, "rb");
  if(fp==NULL) {
    printf("Can not open '%s'\n", img_file);
    assert(0);
  }

  fseek(fp, 0, SEEK_END);
  long size = ftell(fp);

//   Log("The image is %s, size = %ld", img_file, size);
    printf("The image is %s, size = %ld\n", img_file, size);

  fseek(fp, 0, SEEK_SET);
  int ret = fread(guest_to_host(RESET_VECTOR), size, 1, fp);
  assert(ret == 1);

  fclose(fp);
  return size;
}

static int parse_args(int argc, char *argv[]) {
  const struct option table[] = {
    {"help"     , no_argument      , NULL, 'h'},
    {0          , 0                , NULL,  0 },
  };
  int o;
  while ( (o = getopt_long(argc, argv, "-h", table, NULL)) != -1) {
    switch (o) {
      case 1: img_file = optarg; return 0;
      default:
        printf("Usage: %s [OPTION...] IMAGE [args]\n\n", argv[0]);
        printf("\n");
        exit(0);
    }
  }
  return 0;
}

void init_monitor(int argc, char *argv[]) {
  /* Perform some global initialization. */

  /* Parse arguments. */
  parse_args(argc, argv);

  /* Load the image to memory. This will overwrite the built-in image. */
  long img_size = load_img();
}