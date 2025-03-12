#!/bin/bash
# Convert a specific CSV file (see SOURCE below) to YAML.

# FIXME:
# - Extract groups (original file "sofar_g3hyd.yaml" has Inverter but and also
# InverterDC, Battery, Grid, GridEPS, Production, Alert and Settings. Same for
# "zcs_azzurro-hyd-zss-hp.yaml")
# - Concatenate values spanned on several registers (Serial Number, Hardware
# Version, etc.)

# The CSV is generated from the tab "Registers" of either next files: (During
# exportation, make sure to double-quote all values)
#SOURCE="https://github.com/user-attachments/files/19204653/MODBUS_SOFAR.HYD-3PH.and.SOFAR.-G3.Modbus.Protocol.2021-10-14_Client.xlsx"
SOURCE="https://github.com/user-attachments/files/17180102/SOFAR-G3.External.Modbus.Protocol-EN-V1.10.20220622.xlsx"

SRC="$(basename "$SOURCE")"
CSV="${SRC/.xlsx/.csv}"
YML="${CSV/.csv/.yaml}"

HEADER="# Source: $SOURCE

default:
  update_interval: 20
  digits: 6

parameters:
  - group: Inverter
    items:"

CMD_REQUIRED="cat sed yq jq"
for c in $CMD_REQUIRED; do
    if ! command -v $c >/dev/null; then
        echo "Command '$c' is required!"
        exit 1
    fi
done

# FIXME: I'm using this "sed HEX" hack to bypass yq converting "0488"(str) to
# 488(int). If you know a better way, please do!
sed 's/,"\([0-9A-F]\+\)",/,"HEX\1",/' "$CSV" \
    |yq -p=csv -o=json \
    |sed 's/"HEX/"0x/' \
    |jq '
    .[] |= {
        name: ."Field",
        description: ."Remarks",
        registers: [ ."Register address" // ."Register address (Hex)" ],
        uom: ."Unit",
        scale: ."Accuracy",
    }
    | map(select(.name!=null))
    | del(..|nulls)
    ' \
    |yq -P \
    > "$YML.tmp"

echo "$HEADER" > "$YML"
sed 's/^- /\n    - /; s/^/    /' "$YML.tmp" >> "$YML"

rm "$YML.tmp"
