#!/usr/bin/env bash
echo "Checking for required packages before starting Canvas..."

# Check if Python is installed
if command -v python3 &> /dev/null; then
    echo "Python 3 is installed"
else
    echo "Python 3 is not installed. Please install Python before using this package."
    exit 1
fi

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "Docker is installed!"
else
    echo "Docker is not installed! You need a container engine. Please install Docker before proceeding."
    exit 1
fi

# Check if Docker Compose is installed
if command -v docker-compose &> /dev/null; then
    echo "Docker Compose is installed!"
else
    echo "Docker Compose is not installed. Please install Docker Compose before proceeding. It usually comes installed with Docker."
    exit 1
fi

# Check if pyyaml is installed
if python3 -c "import pkg_resources; pkg_resources.get_distribution('pyyaml')" &> /dev/null; then
    echo "PyYAML is installed"
else
    echo "PyYAML is not installed. Installing..."
    pip3 install pyyaml prompt_toolkit --break-system-packages
    if [ $? -ne 0 ]; then
        echo "Failed to install PyYAML. Exiting..."
        exit 1
    fi
fi

clear
python3 main.py