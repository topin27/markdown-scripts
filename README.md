---
title: 一些操作 markdown 的小工具
---

# 使用方式

1. 将当前仓库作为 markdown 知识库的 submodule 并将该 submodule 取名为 `scripts`。
2. 在 markdown 知识库中使用当前仓库中的工具。
3. 可以直接在仓库中的 Makefile 中 include 当前目录中的 header.mk。

# 测试

在 `test/` 目录下搭建了测试环境，执行以下命令进行测试：

```bash
cd test

# 编译所有 markdown 文件
make

# 查看可用目标
make help

# 编译单个文件
make subdir/notes.html

# 检查未引用的资源文件，预期会有一个失败。
make check

# 清理生成的 HTML 文件
make clean
```

# 依赖

* pandoc
* ripgrep
* Python package: pandocfilters
