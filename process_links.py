#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import os
from pandocfilters import toJSONFilter, Link, stringify

ERRORS = []


def get_meta_string(meta_value):
    """Helper to extract a plain string from a Pandoc MetaValue object."""
    try:
        if meta_value['t'] == 'MetaString':
            return meta_value['c']
        # For MetaInlines, MetaBlocks, etc., stringify the content list
        return stringify(meta_value.get('c', ''))
    except (KeyError, TypeError, AttributeError):
        return ''


def _parse_url_parts(url):
    """Split a URL into (path_part, query_part, anchor_part)."""
    path_part = url
    anchor_part = ''
    if '#' in path_part:
        path_part, anchor_part = path_part.split('#', 1)
        anchor_part = '#' + anchor_part

    query_part = ''
    if '?' in path_part:
        path_part, query_part = path_part.split('?', 1)
        query_part = '?' + query_part

    return path_part, query_part, anchor_part


def _convert_ext_to_html(relative_path):
    """Convert .md extension to .html (case-insensitive)."""
    if relative_path.lower().endswith('.md'):
        return relative_path[:-3] + '.html'
    return relative_path


def validate_and_convert(url, source_file):
    """
    Validates an internal link and converts it to a path relative to source_file.

    Link types:
      /docs/a.md  — project-root-relative (absolute path from project root)
      docs/a.md   — same as above (bare path defaults to project-root-relative)
      ./b.md      — source-file-relative (relative to the current file)
      ../b.md     — source-file-relative

    Collects all errors into the global ERRORS list so every link in the
    document is checked and reported in a single compilation run.

    Returns the converted URL string, or None if validation failed.
    """
    project_root = os.getcwd()
    source_dir = os.path.dirname(os.path.abspath(source_file))

    # Source-file-relative links: ./ or ../
    if url.startswith('./') or url.startswith('../'):
        path_part, query_part, anchor_part = _parse_url_parts(url)
        target_abs_path = os.path.normpath(os.path.join(source_dir, path_part))
        if not os.path.exists(target_abs_path):
            ERRORS.append(
                f"Broken Link Error: URL '{url}' in file '{source_file}' "
                f"resolves to non-existent path '{target_abs_path}'."
            )
            return None
        return _convert_ext_to_html(path_part) + query_part + anchor_part

    # Project-root-relative links: /docs/a.md or docs/a.md (bare path)
    if not url.startswith('/'):
        url = '/' + url

    path_part, query_part, anchor_part = _parse_url_parts(url)

    # Root-level link (e.g., / or /#section)
    if path_part == '' or path_part == '/':
        relative = os.path.relpath(project_root, source_dir)
        if relative == '.':
            return '.' + query_part + anchor_part
        else:
            return relative + '/' + query_part + anchor_part

    target_abs_path = os.path.join(project_root, path_part.lstrip('/'))
    if not os.path.exists(target_abs_path):
        ERRORS.append(
            f"Broken Link Error: URL '{url}' in file '{source_file}' "
            f"resolves to non-existent path '{target_abs_path}'."
        )
        return None

    relative_path = os.path.relpath(target_abs_path, source_dir)
    return _convert_ext_to_html(relative_path) + query_part + anchor_part


def process_link(key, value, format, meta):
    """Pandoc filter to validate and convert a single link element."""
    if key != 'Link':
        return None

    attr, content, target = value
    url, title = target

    if url.startswith(('http://', 'https://', 'ftp://', 'mailto:', '#')):
        return None

    try:
        source_file = get_meta_string(meta['source_file'])
        if not source_file:
            ERRORS.append(
                f"Error: Empty or unparseable 'source_file' metadata. "
                f"Cannot process internal link '{url}'."
            )
            return None
    except KeyError:
        ERRORS.append(
            f"Error: Could not find 'source_file' in pandoc metadata. "
            f"Cannot process internal link '{url}'."
        )
        return None

    new_url = validate_and_convert(url, source_file)
    if new_url is None:
        return None

    return Link(attr, content, (new_url, title))


if __name__ == "__main__":
    toJSONFilter(process_link)
    if ERRORS:
        for error in ERRORS:
            sys.stderr.write(error + '\n')
        sys.exit(1)
