#!/usr/bin/env python3
"""merge.py —— 递归检测并合并目录下的所有文本文件。

功能:
  1. 递归扫描指定目录下的所有普通文件;
  2. 按内容检测是否为文本文件(含 NUL 字节者视为二进制, 自动跳过);
  3. 按相对路径排序后合并到同一个输出文件中;
  4. 在每个文件内容前注明其相对路径与文件名。

环境: Linux (Ubuntu) + Python 3.8+
"""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
from pathlib import Path

CHUNK_SIZE = 64 * 1024


def is_text_file(path: Path, chunk_size: int = 8192) -> bool:
    """判断是否为文本文件: 内容中出现 NUL 字节则视为二进制。

    空文件按文本处理 (与原 bash 脚本中 grep -I 的行为一致)。
    """
    try:
        if path.stat().st_size == 0:
            return True
        with path.open("rb") as fp:
            while True:
                chunk = fp.read(chunk_size)
                if not chunk:
                    return True
                if b"\x00" in chunk:
                    return False
    except OSError:
        return False


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="merge-texts.py",
        description="递归检测并合并目录下的所有文本文件, 在每个文件内容前注明相对路径。",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "示例:\n"
            "  merge-texts.py -d ~/notes -o ~/all.txt\n"
            "  merge-texts.py /var/log -o /tmp/logs.txt\n"
            "\n"
            "说明:\n"
            "  * 输出文件若位于源目录内, 会被自动排除, 不会合并进自身;\n"
            "  * 只处理普通文件, 不跟随符号链接;\n"
            "  * 同时给出位置参数与 -d 时, 以 -d 为准。"
        ),
    )
    parser.add_argument(
        "directory", nargs="?", default=None, help="源目录 (默认: 当前目录)"
    )
    parser.add_argument(
        "-d", "--dir", dest="directory_opt", default=None, metavar="DIR",
        help="源目录 (默认: 当前目录)",
    )
    parser.add_argument(
        "-o", "--output", default="merged.txt", metavar="FILE",
        help="输出文件 (默认: ./merged.txt)",
    )
    parser.add_argument(
        "-s", "--separator", default="=", metavar="CHAR",
        help="分隔线字符 (默认: '=')",
    )
    parser.add_argument(
        "-w", "--width", type=int, default=78, metavar="N",
        help="分隔线宽度 (默认: 78)",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    prog = parser.prog

    # ---------- 参数校验与路径规范化 ----------
    src_arg = args.directory_opt or args.directory or "."
    src_dir = Path(src_arg).expanduser()
    if not src_dir.is_dir():
        print(f"{prog}: 目录不存在或不是目录: {src_arg}", file=sys.stderr)
        return 1
    src_dir = src_dir.resolve()

    if args.width < 1:
        print(f"{prog}: 分隔线宽度必须为正整数: {args.width}", file=sys.stderr)
        return 1

    sep_char = args.separator[:1] or "="
    sep_line = sep_char * args.width

    out_path = Path(args.output).expanduser()
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path = out_path.resolve()

    # ---------- 收集待处理文件 (排序, 不跟随符号链接) ----------
    candidates: list[Path] = []
    for root, _dirs, files in os.walk(src_dir, followlinks=False):
        for name in files:
            candidates.append(Path(root) / name)
    candidates.sort()

    # ---------- 主流程 ----------
    total = 0
    merged = 0

    fd, tmp_name = tempfile.mkstemp(
        dir=str(out_path.parent), prefix=".merge-texts-", suffix=".tmp"
    )
    tmp_path = Path(tmp_name)

    try:
        with os.fdopen(fd, "wb") as out_fp:
            for path in candidates:
                # 跳过符号链接与非普通文件
                if path.is_symlink() or not path.is_file():
                    continue

                total += 1

                # 跳过输出文件自身
                try:
                    if path.resolve() == out_path:
                        continue
                except OSError:
                    pass

                # 跳过二进制文件
                if not is_text_file(path):
                    continue

                rel = path.relative_to(src_dir).as_posix()
                merged += 1

                header = (
                    f"\n{sep_line}\n"
                    f"# 文件: {rel}\n"
                    f"{sep_line}\n\n"
                ).encode("utf-8")
                out_fp.write(header)

                # 流式拷贝原始字节, 保留原编码
                last_byte = b""
                with path.open("rb") as in_fp:
                    while True:
                        chunk = in_fp.read(CHUNK_SIZE)
                        if not chunk:
                            break
                        out_fp.write(chunk)
                        last_byte = chunk[-1:]

                # 原文件末尾无换行符时补一个, 避免与下一个文件头粘连
                if last_byte and last_byte != b"\n":
                    out_fp.write(b"\n")

        if merged == 0:
            tmp_path.unlink(missing_ok=True)
            print(f"{prog}: 在 {src_dir} 中未找到任何文本文件。", file=sys.stderr)
            return 0

        os.replace(tmp_path, out_path)

    except BaseException:
        tmp_path.unlink(missing_ok=True)
        raise

    print(f"{prog}: 扫描 {total} 个文件, 合并 {merged} 个文本文件 -> {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
