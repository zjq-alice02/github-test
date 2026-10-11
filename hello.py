"""一个用来演示 git 提交循环的小脚本。

改一改下面的 GREETING，再按 NOTES.md 里的步骤提交一次，
你就能看到 GitHub 上多出一条新的提交记录。
"""

# 试着把这句话改成别的，然后提交看看效果
GREETING = "你好，GitHub！"

# 想加人也可以，往列表里追加就行
NAMES = ["小红", "小明"]


def greet(name: str) -> str:
    """生成一句问候。"""
    return f"{name}，{GREETING}"


def main() -> None:
    print("=" * 30)
    for name in NAMES:
        print(greet(name))
    print("=" * 30)


if __name__ == "__main__":
    main()
