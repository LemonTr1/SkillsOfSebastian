: "
name: hash_tool
description: 哈希计算/识别/完整性校验工具
parameters: $1=操作(calc|identify|verify)
  calc: $2=文件路径或字符串, $3=算法(md5|sha1|sha256|sha512, default: sha256)
  identify: $2=哈希值
  verify: $2=文件路径, $3=期望哈希值, $4=算法(default: sha256)
"
# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

ACTION="${1:?用法: hash_tool.sh <calc|identify|verify> ...}"
shift

case "$ACTION" in
    calc)
        INPUT="${1:?用法: calc <文件路径或字符串> [算法]}"
        ALGO="${2:-sha256}"

        # 判断输入是文件还是字符串
        if [ -f "$INPUT" ]; then
            SRC="file"
        else
            SRC="string"
        fi

        # 选择哈希工具
        case "$ALGO" in
            md5|md5sum)   CMD="md5sum";;
            sha1|sha1sum) CMD="sha1sum";;
            sha224)       CMD="sha224sum";;
            sha256)       CMD="sha256sum";;
            sha384)       CMD="sha384sum";;
            sha512)       CMD="sha512sum";;
            sha3-256)     CMD="sha3-256sum";;
            sha3-512)     CMD="sha3-512sum";;
            *)
                echo "{\"error\":\"不支持的算法: $ALGO\"}"
                echo "支持: md5, sha1, sha224, sha256, sha384, sha512, sha3-256, sha3-512"
                exit 1
                ;;
        esac

        if ! command -v "$CMD" > "$DEVNULL"; then
            echo "{\"error\":\"$CMD 工具不可用\"}"
            exit 1
        fi

        if [ "$SRC" = "file" ]; then
            HASH=$("$CMD" "$INPUT" 2>"$DEVNULL" | awk '{print $1}')
            echo "{\"source\":\"file\",\"path\":\"$INPUT\",\"algorithm\":\"$ALGO\",\"hash\":\"$HASH\"}"
        else
            HASH=$(printf '%s' "$INPUT" | "$CMD" 2>"$DEVNULL" | awk '{print $1}')
            echo "{\"source\":\"string\",\"length\":$(echo -n "$INPUT" | wc -c),\"algorithm\":\"$ALGO\",\"hash\":\"$HASH\"}"
        fi
        ;;

    identify)
        HASH="${1:?用法: identify <哈希值>}"
        HASH=$(echo "$HASH" | tr 'A-F' 'a-f' | tr -d '[:space:]')

        # 合法性检查
        if ! echo "$HASH" | grep -qE '^[0-9a-f]+$'; then
            echo "{\"hash\":\"$HASH\",\"valid\":false,\"error\":\"不是有效的十六进制哈希值\"}"
            exit 0
        fi

        LEN=${#HASH}

        # 根据长度和常见前缀识别
        POSSIBLE=()
        case $LEN in
            32) POSSIBLE=("MD5" "NTLM" "MySQL323");;
            40) POSSIBLE=("SHA1" "MySQL5" "RIPEMD-160");;
            56) POSSIBLE=("SHA224" "SHA3-224");;
            64) POSSIBLE=("SHA256" "SHA3-256" "BLAKE2s");;
            96) POSSIBLE=("SHA384" "SHA3-384");;
            128) POSSIBLE=("SHA512" "SHA3-512" "BLAKE2b");;
            *)
                echo "{\"hash\":\"$HASH\",\"length\":$LEN,\"possible_algorithms\":[],\"error\":\"长度$LEN无法匹配常见哈希算法\"}"
                exit 0
                ;;
        esac

        # 进一步判断（NTLM/MySQL等特殊前缀）
        case $HASH in
            \$2a\$*|\$2b\$*|\$2y\$*) POSSIBLE=("bcrypt");;
            \$6\$*) POSSIBLE=("sha512crypt");;
            \$5\$*) POSSIBLE=("sha256crypt");;
            \$1\$*) POSSIBLE=("MD5-crypt");;
        esac

        echo "{\"hash\":\"$HASH\",\"length\":$LEN,\"possible_algorithms\":[\"$(echo "${POSSIBLE[@]}" | sed 's/ /\",\"/g')\"],\"note\":\"如需确认请使用hashcat --example-hashes 或在线数据库比对\"}"
        ;;

    verify)
        FILE="${1:?用法: verify <文件路径> <期望哈希> [算法]}"
        EXPECTED="${2:?缺少期望哈希值}"
        ALGO="${3:-sha256}"

        case "$ALGO" in
            md5)   CMD="md5sum";;
            sha1)  CMD="sha1sum";;
            sha224) CMD="sha224sum";;
            sha256) CMD="sha256sum";;
            sha384) CMD="sha384sum";;
            sha512) CMD="sha512sum";;
            *) echo "{\"error\":\"不支持的算法: $ALGO\"}"; exit 1;;
        esac

        if [ ! -f "$FILE" ]; then
            echo "{\"error\":\"文件不存在: $FILE\"}"
            exit 1
        fi

        ACTUAL=$("$CMD" "$FILE" 2>"$DEVNULL" | awk '{print $1}')
        EXPECTED_NORM=$(echo "$EXPECTED" | tr 'A-F' 'a-f' | tr -d '[:space:]')

        if [ "$ACTUAL" = "$EXPECTED_NORM" ]; then
            echo "{\"file\":\"$FILE\",\"algorithm\":\"$ALGO\",\"actual_hash\":\"$ACTUAL\",\"match\":true,\"status\":\"✅ 校验通过，文件完整\"}"
        else
            echo "{\"file\":\"$FILE\",\"algorithm\":\"$ALGO\",\"actual_hash\":\"$ACTUAL\",\"expected_hash\":\"$EXPECTED_NORM\",\"match\":false,\"status\":\"❌ 校验失败，文件可能被篡改或损坏\"}"
        fi
        ;;

    *)
        echo "{\"error\":\"未知操作: $ACTION\"}"
        echo "用法: hash_tool.sh <calc|identify|verify> ..."
        exit 1
        ;;
esac
