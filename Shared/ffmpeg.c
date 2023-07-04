//
//  ffmpeg.c
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//

#include "ffmpeg.h"
AVFormatContext * get_format_ctx(const char *url) {
    AVFormatContext *fmt_ctx = NULL;
    int ret;
    if ((ret = avformat_open_input(&fmt_ctx, url, NULL, NULL)))
        return NULL;
    
    if ((ret = avformat_find_stream_info(fmt_ctx, NULL)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find stream information\n");
        return NULL;
    }
    return fmt_ctx;
}

