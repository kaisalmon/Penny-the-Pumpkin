# Makefile for Penny the Pumpkin

.PHONY: test test-verbose clean help install-lua

# Default target
help:
	@echo "Penny the Pumpkin - Make Targets"
	@echo "================================="
	@echo "  make test          - Run all unit tests"
	@echo "  make test-verbose  - Run tests with verbose output"
	@echo "  make install-lua   - Install Lua (Ubuntu/Debian only)"
	@echo "  make clean         - Clean up temporary files"
	@echo "  make help          - Show this help message"

# Run all tests
test:
	@echo "Running Penny the Pumpkin unit tests..."
	@lua tests/run_tests.lua

# Run tests with verbose output
test-verbose:
	@echo "Running tests with verbose output..."
	@lua -e "package.path = package.path .. ';./?.lua'; require('tests/run_tests')"

# Install Lua (Ubuntu/Debian)
install-lua:
	@echo "Installing Lua 5.4..."
	@sudo apt-get update
	@sudo apt-get install -y lua5.4
	@lua -v

# Clean temporary files
clean:
	@echo "Cleaning temporary files..."
	@find . -name "*.tmp" -delete
	@find . -name "*~" -delete
	@echo "Clean complete"

# Continuous integration test (for CI/CD)
ci-test: test
	@echo "CI tests completed successfully"
