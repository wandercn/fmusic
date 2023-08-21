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
#if DEBUG
    av_dump_format(fmt_ctx,0,0,0);
#endif
    
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

int modify_meta(const char* in_filename,const char* out_filename ,AVDictionary * new_metadata)
{
    const AVOutputFormat *oformat = NULL;
    AVFormatContext *ifmt_ctx = NULL, *ofmt_ctx = NULL;
    AVPacket *pkt = NULL;
    int ret, i;
    int stream_index = 0;
    int *stream_mapping = NULL;
    int stream_mapping_size = 0;
    pkt = av_packet_alloc();
    if (!pkt) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Could not allocate AVPacket\n",LOG_HEAD);
        return -1;
    }
    
    if ((ret = avformat_open_input(&ifmt_ctx, in_filename, 0, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Could not open input file: %s\n",LOG_HEAD,in_filename);
        goto end;
    }
    
    if ((ret = avformat_find_stream_info(ifmt_ctx, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed to retrieve input stream information\n",LOG_HEAD);
        goto end;
    }
#if DEBUG
    
    av_dump_format(ifmt_ctx, 0, in_filename, 0);
#endif
    
    
    
    oformat =  av_guess_format(&ifmt_ctx->iformat->extensions[0], in_filename, ifmt_ctx->iformat->mime_type);
    avformat_alloc_output_context2(&ofmt_ctx,oformat,ifmt_ctx->iformat->extensions, out_filename);
    if (!ofmt_ctx) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Could not create output context\n",LOG_HEAD);
        ret = AVERROR_UNKNOWN;
        goto end;
    }
    
    stream_mapping_size = ifmt_ctx->nb_streams;
    stream_mapping = av_calloc(stream_mapping_size, sizeof(*stream_mapping));
    if (!stream_mapping) {
        ret = AVERROR(ENOMEM);
        goto end;
    }
    
    for (i = 0; i < ifmt_ctx->nb_streams; i++) {
        AVStream *out_stream;
        AVStream *in_stream = ifmt_ctx->streams[i];
        AVCodecParameters *in_codecpar = in_stream->codecpar;
        
        if (in_codecpar->codec_type != AVMEDIA_TYPE_AUDIO &&
            in_codecpar->codec_type != AVMEDIA_TYPE_VIDEO &&
            in_codecpar->codec_type != AVMEDIA_TYPE_SUBTITLE) {
            stream_mapping[i] = -1;
            continue;
        }
        
        stream_mapping[i] = stream_index++;
        
        out_stream = avformat_new_stream(ofmt_ctx, NULL);
        if (!out_stream) {
            av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed allocating output stream\n",LOG_HEAD);
            ret = AVERROR_UNKNOWN;
            goto end;
        }
        
        ret = avcodec_parameters_copy(out_stream->codecpar, in_codecpar);
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed to copy codec parameters\n",LOG_HEAD);
            goto end;
        }
        out_stream->codecpar->codec_tag = 0;
        // copy 每个stream中的metaData
        ret = av_dict_copy(&out_stream->metadata, in_stream->metadata, AV_DICT_DONT_OVERWRITE);
        
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed to copy metadata\n",LOG_HEAD);
            goto end;
        }
        
        out_stream->av_class = in_stream->av_class;
        out_stream->disposition = in_stream->disposition;
        out_stream->duration = in_stream->duration;
        out_stream->start_time = in_stream->start_time;
        out_stream->sample_aspect_ratio = in_stream->sample_aspect_ratio;
        out_stream->r_frame_rate = in_stream->r_frame_rate;
        out_stream->avg_frame_rate = in_stream ->avg_frame_rate;
        out_stream->codecpar = in_stream->codecpar;
        out_stream->time_base = in_stream ->time_base;
        out_stream->pts_wrap_bits = in_stream->pts_wrap_bits;
        if (in_stream->codecpar->codec_type == AVMEDIA_TYPE_VIDEO){
            ret = av_packet_copy_props(&out_stream->attached_pic, &in_stream->attached_pic);
            if (ret < 0) {
                av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed to copy attached_pic\n",LOG_HEAD);
                goto end;
            }
            int in_width= in_stream->codecpar->width;
            int in_height= in_stream->codecpar->height;

            if (in_width == 0){
                in_width = 1024;
            }
            if (in_height == 0) {
                in_height = 1024;
            }
            out_stream->codecpar->width = in_width;
            out_stream->codecpar->height = in_height;
            out_stream->codecpar->codec_type = AVMEDIA_TYPE_VIDEO;
            
        }
        
    }
    // copy 原始的元信息
    ret = av_dict_copy(&ofmt_ctx->metadata, ifmt_ctx->metadata, AV_DICT_DONT_OVERWRITE);
    
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Failed to copy metadata\n",LOG_HEAD);
        goto end;
    }
    
    ofmt_ctx->duration = ifmt_ctx->duration;
    ofmt_ctx->start_time = ifmt_ctx->start_time;
    ofmt_ctx->bit_rate = ifmt_ctx->bit_rate;
    ofmt_ctx->flags = ifmt_ctx->flags;
    ofmt_ctx->chapters = ifmt_ctx->chapters;
    ofmt_ctx->nb_chapters = ifmt_ctx->nb_chapters;
    ofmt_ctx->avio_flags = ifmt_ctx->avio_flags;
    ofmt_ctx->av_class = ifmt_ctx->av_class;
//    av_dict_set(&ofmt_ctx->metadata, "duration", NULL, 0);
//    av_dict_set(&ofmt_ctx->metadata, "creation_time", NULL, 0);
//    av_dict_set(&ofmt_ctx->metadata, "company_name", NULL, 0);
//    av_dict_set(&ofmt_ctx->metadata, "product_name", NULL, 0);
//    av_dict_set(&ofmt_ctx->metadata, "product_version", NULL, 0);
    const AVDictionaryEntry *next = NULL;
    // 设置新的元信息
    while ((next = av_dict_iterate(new_metadata, next))){
        av_dict_set(&ofmt_ctx->metadata, next->key, next->value, 0);
    }
    
#if DEBUG
    av_dump_format(ofmt_ctx, 0, out_filename, 1);
#endif
    
    if (!(oformat->flags & AVFMT_NOFILE)) {
        ret = avio_open(&ofmt_ctx->pb, out_filename, AVIO_FLAG_WRITE);
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Could not open output file '%s'\n",LOG_HEAD,out_filename);
            goto end;
        }
    }
    
//    ofmt_ctx->streams[0]->codecpar->codec_type = AVMEDIA_TYPE_AUDIO;
    ofmt_ctx->nb_streams = ifmt_ctx->nb_streams;
    ret = avformat_write_header(ofmt_ctx, NULL);
    if (ret < 0) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Error occurred when opening output file\n",LOG_HEAD);
        goto end;
    }
//    ofmt_ctx->nb_streams ++;
    while (1) {
        AVStream *in_stream, *out_stream;
        
        ret = av_read_frame(ifmt_ctx, pkt);
        if (ret < 0)
            break;
        
        in_stream  = ifmt_ctx->streams[pkt->stream_index];
        if (pkt->stream_index >= stream_mapping_size ||
            stream_mapping[pkt->stream_index] < 0) {
            av_packet_unref(pkt);
            continue;
        }
        pkt->stream_index = stream_mapping[pkt->stream_index];
        out_stream = ofmt_ctx->streams[pkt->stream_index];
        
        /* copy packet */
        av_packet_rescale_ts(pkt, in_stream->time_base, out_stream->time_base);
        pkt->pos = -1;
        
        ret = av_interleaved_write_frame(ofmt_ctx, pkt);
        /* pkt is now blank (av_interleaved_write_frame() takes ownership of
         * its contents and resets pkt), so that no unreferencing is necessary.
         * This would be different if one used av_write_frame(). */
        if (ret < 0) {
            av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Error muxing packet\n",LOG_HEAD);
            break;
        }
    }
    
    av_write_trailer(ofmt_ctx);
    av_log(NULL, AV_LOG_INFO, "[%d]<%s>%s %s - 修改元信息成功\n",LOG_HEAD,in_filename);
end:
    av_packet_free(&pkt);
    
    avformat_close_input(&ifmt_ctx);
    
    /* close output */
    if (ofmt_ctx && !(oformat->flags & AVFMT_NOFILE)){
        avio_closep(&ofmt_ctx->pb);
    }
    
    av_freep(&stream_mapping);
    
    if (ret < 0 && ret != AVERROR_EOF) {
        av_log(NULL, AV_LOG_ERROR, "[%d]<%s>%s Error occurred: %s\n",LOG_HEAD,av_err2str(ret));
        return -1;
    }
    
    return 0;
}

int replace_file(const char *dst , const char *src)
{
    if (remove(dst)){
        av_log(NULL, AV_LOG_DEBUG, "[%d]<%s>%s remove old file: %s fail\n",LOG_HEAD,dst);
        return  -1;
    }
    if (rename(src,dst)){
        av_log(NULL,AV_LOG_DEBUG,"[%d]<%s>%s replace file: %s fail\n",LOG_HEAD,dst);
        return  -1;
    }
    return  0;
}
