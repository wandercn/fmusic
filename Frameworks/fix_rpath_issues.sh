#!/bin/bash
# ====================================================
#   Copyright (C) 2025  All rights reserved.
#
#   Author        : wander
#   Email         : wander@ffactory.org
#   File Name     : fix_rpath_issues.sh
#   Last Modified : 2025-11-17 14:50
#   Describe      : 
#
# ====================================================
# #!/bin/bash

# 修复动态库中不正确的@rpath路径（如/@rpath/）
# 使用方法：将脚本保存为fix_rpath_issues.sh，赋予执行权限后在dylib所在目录运行

# 检查是否有dylib文件
if ! ls *.dylib &> /dev/null; then
    echo "错误：当前目录未找到任何.dylib文件"
    echo "请在动态库所在目录运行此脚本"
    exit 1
fi

# 检查是否安装了必要工具
if ! command -v otool &> /dev/null || ! command -v install_name_tool &> /dev/null; then
    echo "错误：未找到otool或install_name_tool，请安装Xcode命令行工具"
    echo "安装命令：xcode-select --install"
    exit 1
fi

# 临时文件用于存储需要处理的库
temp_file=$(mktemp)

# 收集所有需要修复的动态库
for lib in *.dylib; do
    # 检查是否包含不正确的/@rpath/路径
    if otool -L "$lib" | grep -q '/@rpath/'; then
        echo "发现问题库: $lib"
        echo "$lib" >> "$temp_file"
    fi
done

# 如果没有需要修复的库，退出
if [ ! -s "$temp_file" ]; then
    echo "未发现需要修复的动态库"
    rm -f "$temp_file"
    exit 0
fi

# 修复每个问题库
while IFS= read -r lib; do
    echo "正在修复: $lib"

    # 确保文件可写
    chmod +w "$lib" 2>/dev/null

    # 获取所有需要替换的路径
    problematic_paths=$(otool -L "$lib" | grep '/@rpath/' | awk '{print $1}' | sort | uniq)

    # 替换每个问题路径
    for old_path in $problematic_paths; do
        new_path=$(echo "$old_path" | sed 's/\/@rpath/@rpath/')
        echo "  替换: $old_path -> $new_path"
        install_name_tool -change "$old_path" "$new_path" "$lib"
    done

    # 检查库的ID是否需要修复
    lib_id=$(otool -D "$lib" 2>/dev/null | tail -n1)
    if echo "$lib_id" | grep -q '/@rpath/'; then
        new_id=$(echo "$lib_id" | sed 's/\/@rpath/@rpath/')
        echo "  修复库ID: $lib_id -> $new_id"
        install_name_tool -id "$new_id" "$lib"
    fi

    echo "  修复完成: $lib"
done < "$temp_file"

# 清理临时文件
rm -f "$temp_file"

echo "所有动态库修复完成"



