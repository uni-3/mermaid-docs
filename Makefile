.PHONY: gen help
.DEFAULT_GOAL := help

gen:
	for file in docs/*.mmd docs/*.md; do \
		docker run --rm -v "$(PWD):/data" -w /data docker.io/minlag/mermaid-cli:latest \
		--input "/data/$$file" --output "/data/$${file%.*}.svg" \
		--iconPacks "@iconify-json/logos" "@iconify-json/mdi"; \
	done

help:
	@echo "Available commands:"
	@echo "  make gen    - Generate SVG files from Mermaid diagrams using Docker"
	@echo "  make help   - Show this help message"
