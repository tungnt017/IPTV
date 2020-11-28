#!/bin/sh
set -e

jre_url='https://cdn.azul.com/zulu-embedded/bin/zulu15.28.51-ca-jre15.0.1-linux_aarch64.tar.gz'
jre_sha1sum=9217EB340CB908E1BF61E6C830D4210CDBDF4C6E
jre_dest=/storage
bubbleupnp_url='https://bubblesoftapps.com/bubbleupnpserver/BubbleUPnPServer-distrib.zip'
bubbleupnp_sha1sum=ac87fe841b407413c35b1bfe06ee572fbe1c81d8
bubbleupnp_dest=/storage/bubbleupnp

echo Downloading jre
mkdir -p "$jre_dest"
jre_archive="${jre_url##*/}"
curl -L "$jre_url" -o "$jre_dest/$jre_archive"

if [ -n "$jre_sha1sum" ]; then

	echo Verifying jre
	printf '%s  %s\n' "$jre_sha1sum" "$jre_dest/$jre_archive" \
	| sha1sum -c /dev/stdin
fi

echo Downloading bubbleupnp
mkdir -p "$bubbleupnp_dest"
bubbleupnp_archive="${bubbleupnp_url##*/}"
curl -L "$bubbleupnp_url" -o "$bubbleupnp_dest/$bubbleupnp_archive"

if [ -n "$bubbleupnp_sha1sum" ]; then

	echo Verifying bubbleupnp
	printf '%s  %s\n' "$bubbleupnp_sha1sum" "$bubbleupnp_dest/$bubbleupnp_archive" \
	| sha1sum -c /dev/stdin
fi

echo Extracting jre
(cd "$jre_dest" && tar xf "$jre_archive" && rm "$jre_archive")

echo Extracting bubbleupnp
(cd "$bubbleupnp_dest" && unzip "$bubbleupnp_archive" && rm "$bubbleupnp_archive")
chmod u+x "$bubbleupnp_dest/launch.sh"

autostart_d=/storage/.config/autostart.d
if ! [ -d "$autostart_d" ]; then

	echo Configuring startup script directory
	(set -v
		mkdir -p "$autostart_d"
	)
	autostart_sh=/storage/.config/autostart.sh
	if [ -e "$autostart_sh" ]; then
		(set -v
			cp "$autostart_sh" "$autostart_d/50-existing.sh"
		)
	fi
	(set -v
		cat >"$autostart_sh" <<-EOF
			#!/bin/sh
			for f in $autostart_d/*; do
				"\$f"
			done
		EOF
		chmod u+x "$autostart_sh"
	)
fi

echo Enabling bubbleupnp at system startup
bubbleupnp_autostart="$autostart_d/80-bubbleupnp.sh"
cat >"$bubbleupnp_autostart" <<-EOF
	#!/bin/sh
	PATH="\$PATH:/storage/zulu15.28.51-ca-jre15.0.1-linux_aarch64/bin" \\
		nohup "$bubbleupnp_dest/launch.sh" &
EOF
chmod u+x "$bubbleupnp_autostart"
