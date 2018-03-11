.PHONY: lambda
.SILENT:

lambda:
	mkdir -p artifacts
	set -e && for pkg in $$(ls lambda); do \
		echo "building $$pkg\n"; \
		GOOS=linux CGO_ENABLED=0 go build -o ./artifacts/$$pkg ./lambda/$$pkg; \
		zip -j ./artifacts/$$pkg.zip ./artifacts/$$pkg; \
	done
