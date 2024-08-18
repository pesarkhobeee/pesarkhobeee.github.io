# Define variables
HUGO := hugo
HUGO_FLAGS := 

# Run the Hugo development server
serve:
	$(HUGO) server -D

# Build the static site
build:
	$(HUGO) $(HUGO_FLAGS)

# Show help message
help:
	@echo "Usage:"
	@echo "  make serve          Start the development server"
	@echo "  make build          Build the site"

.PHONY: serve build help
