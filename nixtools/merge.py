#!/usr/bin/env python3
import argparse,os,sys,tempfile
from pathlib import Path
T=65536
def t(p):
 try:
  with p.open("rb") as f:
   while (c:=f.read(8192)):
    if b"\0" in c:return False
  return True
 except OSError:return False
P=argparse.ArgumentParser(prog="merge-texts.py")
P.add_argument("directory",nargs="?");P.add_argument("-d","--dir",dest="directory_opt");P.add_argument("-o","--output",default="merged.txt");P.add_argument("-s","--separator",default="=");P.add_argument("-w","--width",type=int,default=78)
a=P.parse_args()
d=a.directory_opt or a.directory or ".";s=Path(d).expanduser()
if not s.is_dir():print(f"{P.prog}: 目录不存在或不是目录: {d}",file=sys.stderr);sys.exit(1)
s=s.resolve()
if a.width<1:print(f"{P.prog}: 分隔线宽度必须为正整数: {a.width}",file=sys.stderr);sys.exit(1)
l=(a.separator[:1] or "=")*a.width;o=Path(a.output).expanduser();o.parent.mkdir(parents=True,exist_ok=True);o=o.resolve()
c=[Path(r)/n for r,_,f in os.walk(s,followlinks=False) for n in f];c.sort()
total=merged=0;fd,tmp=tempfile.mkstemp(dir=str(o.parent),prefix=".merge-texts-",suffix=".tmp");tmp=Path(tmp)
try:
 with os.fdopen(fd,"wb") as w:
  for x in c:
   if x.is_symlink() or not x.is_file():continue
   total+=1
   try:
    if x.resolve()==o:continue
   except OSError:pass
   if not t(x):continue
   rel=x.relative_to(s).as_posix();merged+=1;w.write(f"\n{l}\n# 文件: {rel}\n{l}\n\n".encode())
   last=b""
   with x.open("rb") as r:
    while (b:=r.read(T)):w.write(b);last=b[-1:]
   if last and last!=b"\n":w.write(b"\n")
 if merged==0:tmp.unlink(missing_ok=True);print(f"{P.prog}: 在 {s} 中未找到任何文本文件。",file=sys.stderr);sys.exit(0)
 os.replace(tmp,o)
except BaseException:
 tmp.unlink(missing_ok=True);raise
print(f"{P.prog}: 扫描 {total} 个文件, 合并 {merged} 个文本文件 -> {o}")
