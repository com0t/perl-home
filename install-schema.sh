#!/usr/bin/env bash

function usage() {
	cat << EOF
usage: $0 <schema> [<alternate-name>]

	Imports the schema named <schema>, based on the definition stored in
	$SQL_HOME/<schema>. If the <alternate-name> argument is given, <schema>
	will be imported into the db under the name <alternate-name>.

	The following variables control aspects of this utility:

	SQL_HOME
		Directory prefix under which schema data is stored.
		Default: /home/risc/sql

	SQL_TMP
		Name of the temporary file created as the concatenation of all
		of the schema definition's files.
		Default: /tmp/<schema>.sql

	SQL_AUTH
		Authentication parameters passed directly to mysql(1).
		Default: none

	SQL_KEEP_TMP
		If true, the SQL_TMP file is not deleted after importing.
		Default: none

EOF
}

function fail() {
	echo "$1"
	exit 1
}

: ${SQL_HOME:="/home/risc/sql"}

SCHEMA="$1"
if [ -z "$SCHEMA" ];then
	usage
	exit 1
fi

case "$SCHEMA" in
	-h|--help) usage; exit 0;;
esac

SCHEMA_NAME="$2"
: ${SCHEMA_NAME:=$SCHEMA}

: ${SQL_TMP:="/tmp/$SCHEMA.sql"}
> $SQL_TMP

cd "$SQL_HOME/$SCHEMA"

while read LINE; do
	cat $LINE >> $SQL_TMP
done < ORDER

mysql $SQL_AUTH -e "CREATE SCHEMA IF NOT EXISTS $SCHEMA_NAME" || fail "failure creating schema $SCHEMA_NAME"
mysql $SQL_AUTH $SCHEMA_NAME < $SQL_TMP || fail "failure importing schema $SCHEMA_NAME"

test -z "$SQL_KEEP_TMP" && rm $SQL_TMP
