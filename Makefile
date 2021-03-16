ifndef SOURCE_PATH
SOURCE_PATH=~/libra
endif

ifndef ARCHIVE_PATH
ARCHIVE_PATH=~/epoch-archive
endif

ifndef DATA_PATH
DATA_PATH=~/.0L
endif

ifndef DB_PATH
DB_PATH=${DATA_PATH}/db
endif

ifndef URL
URL=http://localhost
endif

ifndef EPOCH_LEN
EPOCH_LEN = 1
endif

ifndef TRANS_LEN
TRANS_LEN = 1
endif

END_EPOCH = $(shell expr ${EPOCH} + ${EPOCH_LEN})

EPOCH_WAYPOINT = $(shell jq -r ".waypoints[0]" ${ARCHIVE_PATH}/${EPOCH}/ep*/epoch_ending.manifest)

EPOCH_HEIGHT = $(shell echo ${EPOCH_WAYPOINT} | cut -d ":" -f 1)

check:
	@if test -z "$$EPOCH"; then \
		echo "Must provide EPOCH in environment" 1>&2; \
		exit 1; \
	fi
	@echo data-path: ${DATA_PATH}
	@echo target-db: ${DB_PATH}
	@echo backup-service-url: ${URL}
	@echo start-epoch: ${EPOCH}
	@echo end-epoch: ${END_EPOCH}
	@echo epoch-height: ${EPOCH_HEIGHT}

wipe: 
	sudo rm -rf ${DB_PATH}

create-folder: check
	@if test ! -d ${ARCHIVE_PATH}/${EPOCH}; then \
		mkdir ${ARCHIVE_PATH}/${EPOCH}; \
	fi

bins:
	cd ${SOURCE_PATH} && cargo build -p backup-cli --release
	sudo cp -f ${SOURCE_PATH}/target/release/db-restore /usr/local/bin/db-restore
	sudo cp -f ${SOURCE_PATH}/target/release/db-backup /usr/local/bin/db-backup
	
commit:
	#save to epoch archive repo for testing
	git add -A && git commit -a -m "epoch archive ${EPOCH} - ${EPOCH_WAYPOINT}" && git push

zip:
	zip -r ${EPOCH}.zip ${EPOCH} 

restore-all: wipe restore-epoch restore-transaction restore-snapshot restore-waypoint restore-yaml
	# Destructive command. node.yaml, and db will be wiped.

restore-latest:
	export EPOCH=$(shell ls | sort -n | tail -1) && make restore-all restore-yaml

backup-all: backup-epoch backup-transaction backup-snapshot

backup-epoch: create-folder
	# IMPORTANT: The db-restore tool assumes you are running this from the location of your backups (likely the epoch-archive git project)
	# The manifest file includes OS paths to chunks. Those paths are relative and fail if this is run outside of epoch-archive

	db-backup one-shot backup --backup-service-address ${URL}:6186 epoch-ending --start-epoch ${EPOCH} --end-epoch ${END_EPOCH} local-fs --dir ${ARCHIVE_PATH}/${EPOCH}
	
backup-transaction: create-folder
	db-backup one-shot backup --backup-service-address ${URL}:6186 transaction --num_transactions ${TRANS_LEN} --start-version ${EPOCH_HEIGHT} local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

backup-snapshot: create-folder
	db-backup one-shot backup --backup-service-address ${URL}:6186 state-snapshot --state-version ${EPOCH_HEIGHT} local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

restore-epoch:
	db-restore --target-db-dir ${DB_PATH} epoch-ending --epoch-ending-manifest ${ARCHIVE_PATH}/${EPOCH}/epoch_ending_${EPOCH}*/epoch_ending.manifest local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

restore-transaction:
	db-restore --target-db-dir ${DB_PATH} transaction --transaction-manifest ${ARCHIVE_PATH}/${EPOCH}/transaction_${EPOCH_HEIGHT}*/transaction.manifest local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

restore-snapshot:
	db-restore --target-db-dir ${DB_PATH} state-snapshot --state-manifest ${ARCHIVE_PATH}/${EPOCH}/state_ver_${EPOCH_HEIGHT}*/state.manifest --state-into-version ${EPOCH_HEIGHT} local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

restore-waypoint:
	@echo ${EPOCH_WAYPOINT} > ${DATA_PATH}/restore_waypoint

restore-yaml:
	@if test ! -d ${DATA_PATH}; then \
		mkdir ${DATA_PATH}; \
	fi
	cp ${ARCHIVE_PATH}/${EPOCH}/fullnode_template.node.yaml ${DATA_PATH}/node.yaml

prod-backup:
	URL=http://167.172.248.37 make backup-all

devnet-backup:
	URL=http://157.230.15.42 make backup-all

chron:
	#get epoch from key_store.json
	#backup-all
	#commit changes
