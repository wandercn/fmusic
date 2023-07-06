//
//  ffmpeg.c
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//

#include "ffmpeg.h"
AVFormatContext * get_format_ctx(const char *url) {
    AVFormatContext *fmt_ctx = NULL;
    AVDictionaryEntry *tag = NULL;
    int ret;
    if ((ret = avformat_open_input(&fmt_ctx, url, NULL, NULL)))
        return NULL;
    
    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find stream information\n");
        return NULL;
    }
    while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
         printf("%s=%s\n", tag->key, tag->value);
//    av_dump_format(fmt_ctx,0,0,0);
    return fmt_ctx;
}

