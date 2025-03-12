#!/bin/bash

DEFDIR="$HOME/dev/ha-solarman/custom_components/solarman/inverter_definitions/"
DEFFILE="sofar_g3hyd.yaml"

DST="${DEFDIR}${DEFFILE}"
SRC="SOFAR-G3.External.Modbus.Protocol-EN-V1.10.20220622.yaml"

OUT=""
yq '.parameters[]|.group' "$DST" |while read group; do
    echo "- group: $group"
    if [ "$group" == "Settings" ]; then
        echo "  update_interval: 300"
    fi
    echo "  items:"
    yq ".parameters[]|select(.group==\"$group\").items[]|.registers" "$DST" |while read line; do
        # echo "$line"
        DESC=""
        REG=""
        for r in $(echo $line |sed 's/\[\(.*\)\].*/\1/; s/\s*//g; s/,/ /g'); do
            REG="$r"
            # echo "$r"
            NAME="$(yq ".parameters[]|.items[]|select(.registers[]==\"$r\")|.name" "$DST")"
            # echo "NAME=$NAME"
            _DESC="$(yq ".parameters[]|.items[]|select(.registers[]==\"$r\")|.description" "$SRC")"
            # echo "DESC=$_DESC"
            if [ -n "$_DESC" ]; then
                if [ "$NAME" != "$_DESC" ]; then
                    DESC+="$(yq ".parameters[]|.items[]|select(.registers[]==\"$r\")|.description" "$SRC" |tr -d '"')\n"
                fi
            fi
        done
        echo "- $(yq ".parameters[]|.items[]|select(.registers[]==\"$REG\")" "$DST")" |sed 's/^/    /; s/^    -/  -/'
        if [ -n "$DESC" ]; then
            echo "    description: |-"
            echo -e "$DESC" |sed 's/^/      /'
        fi
    done
done >out.yaml
yq e '.|.parameters *= load("out.yaml")' -i "$DST"
rm out.yaml
