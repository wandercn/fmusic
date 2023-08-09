//
//  ffmpeg.c
//  music (macOS)
//
//  Created by lsmiao on 2023/6/29.
//


#define LOG_HEAD __LINE__,__func__,__FILE__

#include "ffmpeg.h"

AVDictionary * new_dict(void) {
    AVDictionary * metadata = NULL;
    return metadata;
}


AVFormatContext * open_audio_file_fmt_ctx(const char *filename) {
    if (LOG_LEVEL_DEBUG) {
        av_log_set_level(AV_LOG_DEBUG);
    }else{
        av_log_set_level(AV_LOG_INFO);
    }
    AVFormatContext *fmt_ctx = NULL;
    AVDictionaryEntry *tag = NULL;
    
    
    if ( avformat_open_input(&fmt_ctx, filename, NULL, NULL)){
        avformat_close_input(&fmt_ctx);
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s avformat_open_input %s failed!\n",LOG_HEAD,filename);
        return NULL;
    }
    if ( avformat_find_stream_info(fmt_ctx, NULL) < 0) {
        avformat_close_input(&fmt_ctx);
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Cannot find stream information\n",LOG_HEAD);
        return NULL;
    }
    while ((tag = av_dict_get(fmt_ctx->metadata, "", tag, AV_DICT_IGNORE_SUFFIX)))
        //        printf("%s=%s\n", tag->key, tag->value);
        av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s tag: %s = %s\n",LOG_HEAD,tag->key, tag->value);
//    av_dump_format(fmt_ctx,0,0,0);
    
    return fmt_ctx;
}

AVPacket *  get_album_cover_image(const char *filename){
    if (LOG_LEVEL_DEBUG) {
        av_log_set_level(AV_LOG_DEBUG);
    }else{
        av_log_set_level(AV_LOG_INFO);
    }
    const AVCodec *dec;
    AVPacket * pkt = NULL;
    AVFormatContext * fmt_ctx = avformat_alloc_context();
    int video_stream_index = -1;
    fmt_ctx = open_audio_file_fmt_ctx(filename);
    
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s file: %s fmt_ctx addr: %p\n",LOG_HEAD,filename,fmt_ctx);
    
    video_stream_index = av_find_best_stream(fmt_ctx, AVMEDIA_TYPE_VIDEO, -1, -1, &dec, 0);
    
    if (video_stream_index < 0){
        av_log(NULL, AV_LOG_INFO, "[%d]<%s>%s file: %s 不存在内嵌专辑图片\n",LOG_HEAD,filename);
        avformat_close_input(&fmt_ctx);
        return NULL;
    }
    // 必须用clone方法，否则avformat_close_input(&fmt_ctx)，内存释放，无法返回数据。
    pkt = av_packet_clone(&fmt_ctx->streams[video_stream_index]->attached_pic);
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s pkt_size: %d\n",LOG_HEAD,pkt->size);
    av_log(NULL, AV_LOG_DEBUG,"[%d]<%s>%s pkt_data: %p\n",LOG_HEAD,pkt->data);
    avformat_close_input(&fmt_ctx);
    av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s ptk_addr: %p\n",LOG_HEAD,pkt);
    return pkt;
}
