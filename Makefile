ifndef SOURCE_PATH
SOURCE_PATH=~/libra
endif

ifndef ARCHIVE_PATH
ARCHIVE_PATH=~/epoch-archive
endif

ifndef DB_PATH
DB_PATH=~/.0L/db
endif

ifndef URL
URL=http://167.172.248.37
endif

EPOCH_LEN = 1;

END_EPOCH = $(shell expr ${EPOCH} + ${EPOCH_LEN})

EPOCH_WAYPOINT = $(shell jq -r ".waypoints[0]" ${ARCHIVE_PATH}/${EPOCH}/ep*/epoch_ending.manifest)

EPOCH_HEIGHT = $(shell echo ${EPOCH_WAYPOINT} | cut -d ":" -f 1)

check:
	@if test -z "$$EPOCH"; then \
		echo "Must provide EPOCH in environment" 1>&2; \
		exit 1; \
	fi
	@echo backup-service-url: ${URL}
	@echo start-epoch: ${EPOCH}
	@echo end-epoch: ${END_EPOCH}
	@echo epoch-height: ${EPOCH_HEIGHT}

create-folder: check
	@if test ! -d ${ARCHIVE_PATH}/${EPOCH}; then \
		mkdir ${ARCHIVE_PATH}/${EPOCH}; \
	fi
bins:
	cd ${SOURCE_PATH} && cargo build -p backup-cli --release
	sudo cp -f ${SOURCE_PATH}/target/release/db-restore /usr/local/bin/db-restore
	sudo cp -f ${SOURCE_PATH}/target/release/db-backup /usr/local/bin/db-backup
	
backup-epoch: create-folder
	# IMPORTANT: The db-restore tool assumes you are running this from the location of your backups (likely the epoch-archive git project)
	# The manifest file includes OS paths to chunks. Those paths are relative and fail if this is run outside of epoch-archive

#Test if the epoch folder exists

	db-backup one-shot backup --backup-service-address ${URL}:6186 epoch-ending --start-epoch ${EPOCH} --end-epoch ${END_EPOCH} local-fs --dir ${ARCHIVE_PATH}/${EPOCH}

commit-backup:
	#save to epoch archive repo for testing
	git add -A && git commit -a -m "epoch archive ${EPOCH} - ${EPOCH_WAYPOINT}" && git push

restore-epoch:
	cargo run --release -p backup-cli --bin db-restore -- --target-db-dir ~/.0L/db epoch-ending --epoch-ending-manifest ~/epoch-archive/epoch_ending_68-.0a14/epoch_ending.manifest local-fs --dir ~/.0L/db 

backup-transaction:
	cargo run --release -p backup-cli --bin db-backup -- one-shot backup transaction --num_transactions 10000 --start-version 37538428 local-fs --dir ~/.0L/db

restore-transaction:
	cargo run --release -p backup-cli --bin db-restore -- --target-db-dir ~/.0L/db transaction --transaction-manifest ~/epoch-archive/transaction_37538428-.215e/transaction.manifest local-fs --dir ~/.0L/db

backup-snapshot:
	cargo run --release -p backup-cli --bin db-backup -- one-shot backup --backup-service-address http://167.172.248.37:6186 state-snapshot --state-version 41315058 local-fs --dir ~/.0L/db

restore-snapshot:
	cargo run --release -p backup-cli --bin db-restore -- --target-db-dir ~/.0L/db state-snapshot --state-manifest ~/epoch-archive/state_ver_41315058.6168/state.manifest --state-into-version 41315058 local-fs --dir ~/.0L/db