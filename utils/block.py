"""
This script processes a given text file and extracts blocks of 'code', 'conversation', and 'text'
enclosed within markdown-style code fences. The type of each block is identified by a keyword
immediately following the opening code fence ('```conversation', '```python', '```text').

Each block is converted into a JSON object, preserving line breaks within the block. These JSON
objects are then outputted to the console.
"""

import argparse
import json
import re

def detect_block_type(block):
    """
    Identifies the block type of the given text line based on the keyword following '```.

    Args:
        block (str): The line of text to identify.

    Returns:
        str: The type of the block ('conversation', 'code', 'text', 'end_block'), or None if the line doesn't start a block.
    """
    if re.match(r'^```conversation', block):
        return 'conversation'
    elif re.match(r'^```python', block):
        return 'code'
    elif re.match(r'^```text', block):
        return 'text'
    elif re.match(r'^```$', block):
        return 'end_block'
    return None

def append_block(blocks, block_type, block_content):
    """
    Appends a block to the given list if the block content is not empty.

    Args:
        blocks (list): The list of blocks to append to.
        block_type (str): The type of the block.
        block_content (str): The content of the block.
    """
    if block_content.strip():  # check if block is not empty
        blocks.append({
            'type': block_type,
            'content': block_content.strip(),
        })

def handle_line(blocks, line, current_block_type, current_block):
    """
    Processes a line of text, updating the current block and its type as needed.

    Args:
        blocks (list): The list of blocks to append to.
        line (str): The line of text to process.
        current_block_type (str): The current block type.
        current_block (str): The current block content.

    Returns:
        tuple: The updated current block type and current block content.
    """
    block_type = detect_block_type(line)
    if block_type:
        if block_type == 'end_block':
            append_block(blocks, current_block_type, current_block)
            current_block = ''
            current_block_type = None
        else:
            current_block_type = block_type
    elif current_block_type is not None:
        current_block += line + '\n'
    return current_block_type, current_block

def process_file(filename):
    """
    Processes a text file, extracting blocks of 'code', 'conversation', and 'text'.

    Args:
        filename (str): The name of the file to process.

    Returns:
        list: A list of JSON objects representing the extracted blocks.
    """
    blocks = []
    current_block = ''
    current_block_type = None

    with open(filename, 'r') as file:
        for line in file:
            line = line.rstrip()  # remove trailing white spaces and newlines
            if line:  # check if line is not empty
                current_block_type, current_block = handle_line(blocks, line, current_block_type, current_block)

    return blocks

def main():
    parser = argparse.ArgumentParser(description='Process a text file into JSON blocks.')
    parser.add_argument('filename', type=str, help='The name of the file to process')
    args = parser.parse_args()

    blocks = process_file(args.filename)
    with open('output.json', 'w') as file:
        json.dump(blocks, file, indent=4)

if __name__ == '__main__':
    main()
