#!/usr/bin/env python3

import html
import sys
import json
from pandocfilters import walk, RawBlock

def mermaid_filter(key, value, format_, meta):
    """
    负责处理文档中的具体节点（不在此处直接修改 meta 字典的键值对结构）。
    """
    if format_ != 'html':
        return

    # 处理正文中的 CodeBlock
    if key == 'CodeBlock':
        [[ident, classes, keyvals], code] = value
        if "mermaid" not in classes:
            return

        # 替换 CodeBlock 为 Mermaid 可识别的 HTML
        safe_code = html.escape(code)
        return RawBlock('html', f'<pre class="mermaid">\n{safe_code}\n</pre>')


def main():
    """
    自定义的入口函数，避免直接使用 toJSONFilter 导致的字典大小变更冲突。
    """
    # 1. 从标准输入读取 Pandoc 传入的 JSON 数据
    doc = json.loads(sys.stdin.read())
    
    # 兼容不同版本的 Pandoc 抽象语法树（AST）
    # 旧版是一个列表 [meta, blocks]；
    # 新版是一个字典 {"pandoc-api-version": ..., "meta": ..., "blocks": ...}
    if isinstance(doc, dict):
        meta = doc.get('meta', {})
        blocks = doc.get('blocks', [])
    else:
        meta = doc[0]
        blocks = doc[1]

    # 获取当前转换的输出格式（从命令行参数中提取，这是 pandocfilters 的标准逻辑）
    format_ = sys.argv[1] if len(sys.argv) > 1 else 'html'

    # 2. 安全地修改元数据 (由于此时还没有开始 walk 遍历，所以绝对不会报错)
    if format_ == 'html':
        mermaid_script = """\
<script type="module">
  import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.esm.min.mjs';
  mermaid.initialize({ startOnLoad: true });
</script>
"""
        meta_script_node = {
            't': 'MetaBlocks',
            'c': [
                {'t': 'RawBlock', 'c': ['html', mermaid_script]}
            ]
        }

        if 'header-includes' in meta:
            current = meta['header-includes']
            if current.get('t') == 'MetaList':
                current['c'].append(meta_script_node)
            else:
                meta['header-includes'] = {'t': 'MetaList', 'c': [current, meta_script_node]}
        else:
            meta['header-includes'] = {'t': 'MetaList', 'c': [meta_script_node]}

    # 3. 执行安全的 walk 遍历，仅用来转换具体的节点
    altered_blocks = walk(blocks, mermaid_filter, format_, meta)

    # 4. 把修改后的数据重新写回并输出
    if isinstance(doc, dict):
        doc['blocks'] = altered_blocks
    else:
        doc[1] = altered_blocks

    sys.stdout.write(json.dumps(doc))


if __name__ == "__main__":
    main()
