package main

import (
	"bufio"
	"embed"
	"fmt"
	"io/fs"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
)

//go:embed dist/*
var content embed.FS

func main() {
	// Get the directory of the executable
	// exePath, err := os.Executable()
	// if err != nil {
	// 	log.Fatalf("Failed to get executable path: %v", err)
	// }
	// dir := filepath.Dir(exePath)

	// Prompt for port with default value
	defaultPort := "8000"
	fmt.Printf("Enter port number (default %s): ", defaultPort)
	reader := bufio.NewReader(os.Stdin)
	input, err := reader.ReadString('\n')
	if err != nil {
		log.Fatalf("Failed to read input: %v", err)
	}
	input = strings.TrimSpace(input)

	// Use default port if input is empty
	port := defaultPort
	if input != "" {
		port = input
	}

	// Validate port
	portNum, err := strconv.Atoi(port)
	if err != nil || portNum < 1 || portNum > 65535 {
		log.Fatalf("Invalid port number: %s. Must be between 1 and 65535.", port)
	}

	// Create a file server handler
	// fs := http.FileServer(http.Dir(dir))
	// http.Handle("/", fs)

	distFS, err := fs.Sub(content, "dist")
	if err != nil {
		log.Fatalf("Failed to access embedded files: %s", err)
	}

	fs := http.FileServer(http.FS(distFS))
	http.Handle("/", fs)

	// Start the server with improved message
	addr := fmt.Sprintf(":%s", port)

	// color := "\033[35m"
	color := "\033[32m"
	color_reset := "\033[0m"

	println(" ")
	fmt.Printf("%sServing files on Address:%s http://localhost%s\n", color, color_reset, addr)
	println(" ")
	err = http.ListenAndServe(addr, nil)
	if err != nil {
		log.Fatalf("Server failed to start: %v", err)
	}
}
