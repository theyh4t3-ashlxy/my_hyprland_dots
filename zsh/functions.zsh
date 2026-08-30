take() {
    if [[ -z "$1" ]]; then
        echo "take what?"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}


reload-qs() {
	{ qs kill; qs -d; } > /dev/null 2>&1
	echo "ok done :)"
}
restart-qs() { reload-qs; }
