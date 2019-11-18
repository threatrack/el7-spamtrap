#!/bin/bash
if [[ $# -ne 2 ]]; then
	echo "usage: ${1} <xx_install_xx.src> <dir>"
	exit
fi

src="${1}"
dir="${2}"

cat "${src}" | grep "# COPY CONFIGURATION FILES" -B 100000000
for i in $(find "${dir}" -type d | sed "s/${dir}//" | grep -v '^$'); do
	echo "mkdir -p ${i}"
done
for i in $(find "${dir}" -type f | sed "s/${dir}//" | grep -v '^$'); do
	if [ "$(file --mime-type "${dir}/${i}" | cut -d' ' -f 2 | grep "text/")" ]; then
		echo "cat > ${i} << PASTECONFIGURATIONFILE"
		cat "${dir}/${i}" | sed 's/\\/\\\\/g;s/\$/\\\$/g;s/`/\\`/g;'
		echo "PASTECONFIGURATIONFILE"
	else
		echo "base64 -d > ${i} << PASTECONFIGURATIONFILE"
		base64 "${dir}/${i}" | sed 's/\\/\\\\/g;s/\$/\\\$/g;s/`/\\`/g;'
		echo "PASTECONFIGURATIONFILE"
	fi
done
cat "${src}" | grep "# COPY CONFIGURATION FILES" -A 100000000

