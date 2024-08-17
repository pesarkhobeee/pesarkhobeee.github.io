#!/bin/bash
        echo -n "what is current main word? (task) "
        read current

        echo -n "what is future main word? (note) "
        read future

        for i in $( find . -name "*$current*" ); do
            echo item: $i
            y=$( echo $i | sed -e "s/$current/$future/" )
            echo replaced: $y
            mv $i $y
        done

        find . -type f -exec sed -i "s/$current/$future/g" {} +

        current=$(echo "$current" | sed 's/.*/\u&/')
        future=$(echo "$future" | sed 's/.*/\u&/')
        echo "now upper case time: "  $current  " with "  $future
        find . -type f -exec sed -i "s/$current/$future/g" {} +
