#! /bin/bash

if [ -z "$OPENAI_API_KEY" ]; then
    echo "OPENAI_API_KEY is not set"
    exit 1
fi

# Create a temporary directory if it doesn't exist
if [ ! -d "/tmp/aider" ]; then
    mkdir -p /tmp/aider
fi

# Clone the Aider repository if it doesn't exist
if [ ! -d "/tmp/aider/aider" ]; then
    git clone https://github.com/Aider-AI/aider.git /tmp/aider/aider
fi

# Create a temporary directory for the benchmarks if it doesn't exist
if [ ! -d "/tmp/aider/tmp.benchmarks" ]; then
    mkdir -p /tmp/aider/tmp.benchmarks
fi

# Clone the repo with the exercises if it doesn't exist
if [ ! -d "/tmp/aider/tmp.benchmarks/polyglot-benchmark" ]; then
    git clone https://github.com/Aider-AI/polyglot-benchmark /tmp/aider/tmp.benchmarks/polyglot-benchmark
fi

# Build the docker container if it doesn't exist
if [ $(docker images | grep aider-benchmark | wc -l) -eq 0 ]; then
    /tmp/aider/aider/benchmark/docker_build.sh
fi

docker run \
       -it --rm \
       --memory=12g \
       --memory-swap=12g \
       --add-host=host.docker.internal:host-gateway \
       -v /tmp/aider/aider:/aider \
       -v /tmp/aider/tmp.benchmarks/.:/benchmarks \
       -e OPENAI_API_KEY=$OPENAI_API_KEY \
       -e HISTFILE=/aider/.bash_history \
       -e PROMPT_COMMAND='history -a' \
       -e HISTCONTROL=ignoredups \
       -e HISTSIZE=10000 \
       -e HISTFILESIZE=20000 \
       -e AIDER_DOCKER=1 \
       -e AIDER_BENCHMARK_DIR=/benchmarks \
       aider-benchmark \
       bash -c "pip install -e .[dev] && ./benchmark/benchmark.py a-helpful-name-for-this-run --model gpt-3.5-turbo --edit-format whole --threads 10 --exercises-dir polyglot-benchmark"


# Run this to print the last results
# docker run -it --rm -v /tmp/aider/aider:/aider -v /tmp/aider/tmp.benchmarks/.:/benchmarks \
#        aider-benchmark \
#        bash -c "/aider/benchmark/benchmark.py --stats /benchmarks/*"