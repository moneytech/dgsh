#!/bin/sh
#
# Regression tests for teebuff
#

ensure_same()
{
	echo "$1"
	if ! diff $2 $3 >/dev/null
	then
		echo "$1: $2 and $3 differ" 1>&2
		exit 1
	fi
}


for flags in '' -i
do
	# Test line scatter reliable algorithm
	cat -n /usr/share/dict/words >words
	./teebuff $flags -sl -b 1000000 <words a b c d
	cat a b c d | sort -n >words2
	ensure_same "Line scatter reliable $flags" words words2

	# Test line scatter efficient algorithm
	./teebuff $flags -sl -b 128 <words a b c d
	cat a b c d | sort -n >words2
	ensure_same "Line scatter efficient $flags" words words2

	# Test with a buffer smaller than line size
	./teebuff $flags -sl -b 5 <words a b c d
	cat a b c d | sort -n >words2
	ensure_same "Small buffer $flags" words words2

	# Test with data less than the buffer size
	head -50 /usr/share/dict/words | cat -n >words
	./teebuff $flags -sl -b 1000000 <words a b c d
	cat a b c d | sort -n >words2
	ensure_same "Large buffer $flags" words words2
	rm words words2

	# Test block scatter
	./teebuff $flags -s -b 64 <teebuff.c a b c d
	./charcount <teebuff.c >orig
	cat a b c d | ./charcount >new
	ensure_same "Block scatter $flags" orig new
	rm a b c d orig new

	# Test plain distribution
	./teebuff $flags -b 64 <teebuff.c a b
	ensure_same "Plain distribution $flags" teebuff.c a
	ensure_same "Plain distribution $flags" teebuff.c b
	rm a b

	# Test output to stdout
	./teebuff $flags -b 64 <teebuff.c >a
	ensure_same "Stdout $flags" teebuff.c a
	rm a

	# Test buffering
	for flags2 in '' -l
	do
		test=teebuff-fastout$flags$flags2
		dd bs=1k count=1024 if=/dev/zero 2>/dev/null | ./teebuff -m $flags $flags2 -b 1024 >/dev/null 2>test/teebuff-buffer/$test.test
		ensure_same "$test" test/teebuff-buffer/$test.ok test/teebuff-buffer/$test.test
		test=teebuff-lagout$flags$flags2
		dd bs=1k count=1024 if=/dev/zero 2>/dev/null | ./teebuff -m $flags $flags2 -b 1024 2>test/teebuff-buffer/$test.test | (sleep 1 ; cat >/dev/null)
		ensure_same "$test" test/teebuff-buffer/$test.ok test/teebuff-buffer/$test.test
	done
done
exit 0