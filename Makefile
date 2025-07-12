.PHONY: gen help
.DEFAULT_GOAL := help

gen:
	docker run --rm -v $(PWD):/data -w /data docker.io/minlag/mermaid-cli:latest \
	mmdc -i ./docs/*.mmd --iconPacks '@iconify-json/logos' '@iconify-json/mdi'

help:
	@echo "Available commands:"
	@echo "  make gen    - Generate SVG files from Mermaid diagrams using Docker"
	@echo "  make help   - Show this help message"
