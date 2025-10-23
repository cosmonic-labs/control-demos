help:
	@./.scripts/run.sh

.PHONY: helm-render-%
helm-render-%:
	@./.scripts/run.sh render $*

.PHONY: helm-install-%
helm-install-%:
	@./.scripts/run.sh install $*

.PHONY: helm-delete-%
helm-delete-%:
	@./.scripts/run.sh delete $*

.PHONY: helm-render
helm-render:
	@./.scripts/run.sh render

.PHONY: helm-install
helm-install:
	@./.scripts/run.sh install

.PHONY: helm-delete
helm-delete:
	@./.scripts/run.sh delete