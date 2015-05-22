#include <stdio.h>
#include <string.h>
#include <setjmp.h>

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/fail.h>
#include <caml/bigarray.h>

#include <jpeglib.h>

struct my_error_mgr {
    struct jpeg_error_mgr pub;    /* "public" fields */
    jmp_buf setjmp_buffer;        /* for return to caller */
};

typedef struct my_error_mgr * my_error_ptr;


/* Routine that replaces the standard error_exit method */
static void
caml_my_error_exit (j_common_ptr cinfo)
{
    my_error_ptr myerr = (my_error_ptr) cinfo->err;
    (*cinfo->err->output_message) (cinfo);
    longjmp(myerr->setjmp_buffer, 1);
}

/* JPEG decompression */
static value
load_jpeg_from_file (value filename)
{
    CAMLparam1(filename);
    CAMLlocal1(ret);

    struct jpeg_decompress_struct cinfo;
    struct my_error_mgr jerr;
    char err_buf[192];
    FILE * infile;

    if ((infile = fopen(String_val(filename), "rb")) == NULL) {
        snprintf(err_buf, 192, "Error: couldn't open jpeg file \"%s\"", String_val(filename));
        caml_failwith(err_buf);
    }

    cinfo.err = jpeg_std_error(&jerr.pub);
    jerr.pub.error_exit = caml_my_error_exit;

    if (setjmp(jerr.setjmp_buffer)) {
        jpeg_destroy_decompress(&cinfo);
        fclose(infile);
        snprintf(err_buf, 192, "Error while loading jpeg file \"%s\"", String_val(filename));
        caml_failwith(err_buf);
    }

    jpeg_create_decompress(&cinfo);

    jpeg_stdio_src(&cinfo, infile);

    (void) jpeg_read_header(&cinfo, TRUE);

    (void) jpeg_start_decompress(&cinfo);
    /*
    (void) jpeg_finish_decompress(&cinfo);
    */

    ret = caml_alloc(2, 0);
    Store_field(ret, 0, Val_int(cinfo.output_width));
    Store_field(ret, 1, Val_int(cinfo.output_height));

    fclose(infile);
    jpeg_destroy_decompress(&cinfo);

    CAMLreturn(ret);
}

static void
mem_init_source (j_decompress_ptr cinfo)
{
    /* nothing to do */
}

static boolean
mem_fill_input_buffer (j_decompress_ptr cinfo)
{
    JOCTET eoi_buffer[2] = { 0xFF, JPEG_EOI };
    struct jpeg_source_mgr *jsrc = cinfo->src;

    /* create a fake EOI marker */
    jsrc->next_input_byte = eoi_buffer;
    jsrc->bytes_in_buffer = 2;

    return TRUE;
}

static void
mem_skip_input_data (j_decompress_ptr cinfo, long num_bytes)
{
  struct jpeg_source_mgr *jsrc = cinfo->src;

  if (num_bytes > 0)
    {
      while (num_bytes > (long)jsrc->bytes_in_buffer)
        {
          num_bytes -= (long)jsrc->bytes_in_buffer;
          mem_fill_input_buffer (cinfo);
        }

      jsrc->next_input_byte += num_bytes;
      jsrc->bytes_in_buffer -= num_bytes;
    }
}

static void
mem_term_source (j_decompress_ptr cinfo)
{
    /* nothing to do */
}

static void
caml_err_exit (j_common_ptr cinfo)
{
    /* get error manager */
    my_error_ptr jerr = (my_error_ptr)(cinfo->err);

    /* display error message */
    (*cinfo->err->output_message) (cinfo);

    /* return control to the setjmp point */
    longjmp (jerr->setjmp_buffer, 1);
}


static value
read_jpeg_from_memory (value buffer)
{
    CAMLparam1(buffer);
    CAMLlocal1(ret);

    struct jpeg_decompress_struct cinfo;
    struct my_error_mgr jerr;
    struct jpeg_source_mgr jsrc;

    /* create and configure decompress object */
    jpeg_create_decompress (&cinfo);
    cinfo.err = jpeg_std_error (&jerr.pub);
    cinfo.src = &jsrc;

    /* configure error manager */
    jerr.pub.error_exit = caml_err_exit;

    if (setjmp (jerr.setjmp_buffer))
    {
        jpeg_destroy_decompress (&cinfo);
        caml_failwith("Error while loading jpeg from buffer");
    }

    /* configure source manager */
    jsrc.next_input_byte = (JOCTET *) String_val(buffer);
    jsrc.bytes_in_buffer = caml_string_length(buffer);
    jsrc.init_source = mem_init_source;
    jsrc.fill_input_buffer = mem_fill_input_buffer;
    jsrc.skip_input_data = mem_skip_input_data;
    jsrc.resync_to_restart = jpeg_resync_to_restart;
    jsrc.term_source = mem_term_source;

    jpeg_read_header (&cinfo, TRUE);

    jpeg_start_decompress (&cinfo);
    /*
    jpeg_finish_decompress (&cinfo);
    */

    ret = caml_alloc(2, 0);
    Store_field(ret, 0, Val_int(cinfo.output_width));
    Store_field(ret, 1, Val_int(cinfo.output_height));

    jpeg_destroy_decompress(&cinfo);

    CAMLreturn(ret);
}


CAMLprim value
caml_load_jpeg_file (value input)
{
    switch (Tag_val(input))
    {
        /* given a filename of an image */
        case 0:
            return load_jpeg_from_file (Field(input,0));
            break;

        /* given the image data in a buffer */
        case 1:
            return read_jpeg_from_memory (Field(input,0));
            break;
    }
    caml_failwith("BUG");
}

// vim: sw=4 sts=4 ts=4 et fdm=marker
