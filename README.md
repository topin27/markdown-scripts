---
title: 一些操作 markdown 的小工具
---

# 使用方式

1. 将当前仓库作为 markdown 知识库的 submodule 并将该 submodule 取名为 `scripts`。
2. 在 markdown 知识库中使用当前仓库中的工具。
3. 可以直接在仓库中的 Makefile 中 include 当前目录中的 header.mk。

# 依赖

* pandoc
* ripgrep
* Python package: pandocfilters
