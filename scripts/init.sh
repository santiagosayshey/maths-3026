#!/bin/bash

# Colors for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Cryptography Assignment Generator ===${NC}"

# Check if template.tex exists
if [ ! -f "template.tex" ]; then
    echo -e "${RED}Error: template.tex not found!${NC}"
    echo "Make sure template.tex is in the same directory as this script."
    exit 1
fi

# Get assignment number
read -p "Assignment number: " assignment_num

# Create filename
filename="assignment${assignment_num}.tex"

# Copy template and replace assignment number
sed "s/{{ASSIGNMENT_NUM}}/$assignment_num/g" template.tex > "$filename"

# Create a temporary file for the problems content
problems_file=$(mktemp)

# Function to add problems to the temp file
add_problem() {
    local problem_num=$1
    echo "" >> "$problems_file"
    echo "\\section*{Problem $problem_num}" >> "$problems_file"
    
    read -p "Does Problem $problem_num have subparts (a, b, c...)? (y/n): " has_subparts
    
    if [[ $has_subparts == "y" ]]; then
        read -p "Enter subparts for Problem $problem_num (e.g., 'a b c' or 'a b c d e'): " subparts
        
        for subpart in $subparts; do
            echo "" >> "$problems_file"
            echo "\\subsection*{($subpart)}" >> "$problems_file"
            
            read -p "Does Problem $problem_num($subpart) have sub-subparts (i, ii, iii...)? (y/n): " has_subsubparts
            
            if [[ $has_subsubparts == "y" ]]; then
                read -p "Enter sub-subparts (e.g., 'i ii iii' or 'i ii iii iv'): " subsubparts
                
                for subsubpart in $subsubparts; do
                    echo "" >> "$problems_file"
                    echo "\\subsubsection*{$subsubpart.}" >> "$problems_file"
                    echo "% Your solution here" >> "$problems_file"
                    echo "" >> "$problems_file"
                done
            else
                echo "% Your solution here" >> "$problems_file"
                echo "" >> "$problems_file"
            fi
        done
    else
        echo "% Your solution here" >> "$problems_file"
        echo "" >> "$problems_file"
    fi
    
    echo "" >> "$problems_file"
    echo "%------------------------" >> "$problems_file"
}

# Get problem structure
read -p "How many problems? " num_problems

for ((i=1; i<=num_problems; i++)); do
    echo -e "${GREEN}Setting up Problem $i...${NC}"
    add_problem $i
done

# Replace {{PROBLEMS}} with the actual problems content
# This uses sed to replace the placeholder with the contents of our temp file
sed -i "/{{PROBLEMS}}/r $problems_file" "$filename"
sed -i "/{{PROBLEMS}}/d" "$filename"

# Clean up temp file
rm "$problems_file"

echo -e "${GREEN}✓ Template saved as $filename${NC}"

# Ask if they want to build
read -p "Build PDF now? (y/n): " build_now

if [[ $build_now == "y" ]]; then
    echo -e "${BLUE}Building PDF...${NC}"
    pdflatex "$filename" > /dev/null 2>&1
    pdflatex "$filename" > /dev/null 2>&1  # Run twice for references
    
    # Clean up auxiliary files
    rm -f *.aux *.log *.out *.toc *.fls *.fdb_latexmk *.synctex.gz
    
    if [ -f "${filename%.tex}.pdf" ]; then
        echo -e "${GREEN}✓ Created ${filename%.tex}.pdf${NC}"
        echo -e "${BLUE}Opening PDF...${NC}"
        xdg-open "${filename%.tex}.pdf" 2>/dev/null &
    else
        echo -e "${RED}✗ PDF build failed. Run 'pdflatex $filename' to see errors.${NC}"
    fi
fi