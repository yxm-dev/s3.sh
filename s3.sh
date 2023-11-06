#! /bin/bash

# S3 FUNCTION
    function s3(){
## Includes
        source ${BASH_SOURCE%/*}/pkgfile
## Auxiliary Functions
        function S3_has_dir(){
            defined_dir="S3_dirs[$1]="
            has_defined_dir=$(grep -F "$defined_dir" $PKG_install_dir/files/bucket_dir)
            if [[ -n "$has_defined_dir" ]]; then
                sed -i "/S3_dirs\[$1\]=/c\S3_dirs[$1]=$2" $PKG_install_dir/files/bucket_dir
            else
                echo "S3_dirs[$1]=$2" >> $PKG_install_dir/files/bucket_dir
            fi
        }
        function S3_buckets_name(){
            name_check=$(aws s3api create-bucket --bucket $1 --region $2 --create-bucket-configuration LocationConstraint=$2 /dev/null 2>&1 | grep "BucketAlreadyExists")
            if [[ -n "$name_check" ]]; then
                echo "error: The name \"$1\" is not available."
                echo "Try another name."
            else
                aws s3api create-bucket --bucket $1 --region $2 --create-bucket-configuration LocationConstraint=$2 /dev/null 2>&1
            fi
        }
        function S3_region_list(){
            echo "The following is the list of available regions:"
            aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text
        }
        function S3_website(){
            S3_has_dir $1 $2
            cp -r $PKG_install_dir/files/website.json $2/website.json
            aws s3api put-bucket-website --bucket $1 --website-configuration file://$2/website.json
            cp -r $PKG_install_dir/files/policy.json $2/policy.json
            sed -i "s/NAME/$1/g" $2/policy.json
            aws s3api put-bucket-policy --bucket $1 --policy file://$2/policy.json
            aws s3api put-object-acl --bucket $1 --key index.html --acl public-read
        }
        function S3_push(){
            mapfile -t S3_buckets < <(aws s3 ls | awk '{print $3}')
            eval "$(cat $PKG_install_dir/files/bucket_dir)"
            if [[ "${S3_buckets[@]}" =~ "$1" ]]; then
                if [[ -z "$2" ]]; then
                    if [[ -n "${S3_dirs[$1]}" ]]; then
                        aws s3 sync ${S3_dirs[$1]} s3://$1 
                        echo "Directory \"${S3_dirs[$1]}\" was pushed to the bucket \"$1\"."
                    else
                        echo "error: There is no directory assigned to the bucket \"$1\"."
                        echo "Try \"aws3 -b $1 -d some_dir\" first."
                    fi
                else
                    echo "error: Please, provide only the bucket from which you want to push."
                fi
            else 
                echo "error: There is no bucket named \"$1\"." 
            fi
        }
        function S3_pull(){
            mapfile -t S3_buckets < <(aws s3 ls | awk '{print $3}')
            eval "$(cat $PKG_install_dir/files/bucket_dir)"
            if [[ "${S3_buckets[@]}" =~ "$1" ]]; then
                if [[ -z "$2" ]]; then
                    if [[ -n "${S3_dirs[$1]}" ]]; then 
                        aws s3 sync s3://$1 ${S3_dirs[$1]} 
                        echo "Directory \"${S3_dirs[$1]}\" was pulled from the bucket \"$1\"."    
                    else
                        echo "error: There is no directory assigned to the bucket \"$1\"."
                        echo "Try \"aws3 -b $1 -d some_dir\" first."
                    fi
                else
                    echo "error: Please, provide only the bucket from which you want to pull."
                fi
            else 
                echo "error: There is no bucket named \"$1\"." 
            fi
        }
## Auxiliary Function: S3_latency_test
        function S3_latency_test(){
            mapfile -t regions < <(aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text)
            smallest_latency=""
            min_latency=9999
            for region in "${regions[@]}"
                do
                    latency=$(ping -c 4 -q s3.$region.amazonaws.com | awk -F '/' 'END {print $5}')
                    if (( $(echo "$latency < $min_latency" | bc -l) )); then
                        min_latency=$latency
                        smallest_latency=$region
                    fi
                done
            echo "The region with the smallest latency is \"$smallest_latency\"."
            echo "Latency value: $min_latency ms"
        }
## Auxiliary Function: S3_set_region
        function S3_set_region(){
            mapfile -t regions < <(aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text)
            if [[ "${regions[@]}" =~ "$1" ]]; then
                echo "S3_region=\"$1\"" >> $PKG_install_dir/pkgfile
                echo "The default region was set to \"$1\"."
            else
                echo "error: \"$1\" is not an available region."
                echo "Check the available regions with \"s3 --region --list\"."
            fi
        }

## S3 Function Properly
### without options print help
        if  [[ -z "$1" ]]; then
                cat $PKG_install_dir/config/help.txt
### "-h" and "--help" options to print help
        elif ([[ "$1" == "-h" ]] || 
              [[ "$1" == "--help" ]]) &&
              [[ -z "$2" ]]; then
            cat $PKG_install_dir/config/help.txt
### "-u" and "--uninstall" options to execute the uninstall script
        elif [[ "$1" == "-u" ]] || [[ "$1" == "--uninstall" ]]; then
            sh $PKG_install_dir/install/uninstall
### "-c" and "--create" to create a bucket
        elif [[ "$1" == "-c" ]] ||  [[ "$1" == "--create" ]]; then
            if [[ -z "$2" ]]; then
                echo "Enter the name of the bucket to be created."
                while :
                do
                    read -e -r -p "> " bucket_name
                    if [[ -n $bucket_name ]]; then
                        if [[ -n $S3_region ]]; then
                            echo "Enter the region in which you want to create the bucket."
                            echo "The default region was set to \"$S3_region\". To select it just hit enter."
                            S3_region_list
                            read -e -r -p "> " bucket_region
                            if [[ -z $bucket_region ]]; then
                                S3_buckets_name $bucket_name $S3_region
                            else 
                                echo "Enter the region in which you want to create the bucket."
                                S3_region_list
                                while :
                                do
                                    read -e -r -p "> " bucket_region
                                    if [[ -z $bucket_region ]]; then
                                        echo "Please, enter a region."
                                        continue
                                    else
                                        S3_buckets_name $bucket_name $bucket_region    
                                    fi
                                done
                                break
                            fi
                        fi
                    else
                        echo "Please, enter a bucket name."
                        continue
                    fi
                done
            elif [[ -n $2 ]] && ([[ "$3" == "-r" ]] || [[ "$3" == "--region" ]]) && [[ -n $4 ]]; then
                mapfile -t S3_buckets < <(aws s3 ls | awk '{print $3}')
                if [[ "${S3_buckets[@]}" =~ "$4" ]]; then
                    S3_buckets_name $2 $4
                else
                    echo "error: \"$4\" is not a valid region."
                fi
            elif [[ -n "$2" ]] && [[ -z "$3" ]]; then
                echo "error: Missing region and default region not defined."
                echo "Enter a region or set it first with \"s3 --set-region your_region\"." 
            fi
### "-d" and "--delete" to delete a bucket
        elif [[ "$1" == "-d" ]] || [[ "$1" == "--delete" ]]; then
            mapfile -t S3_buckets < <(aws s3 ls | awk '{print $3}')
            if [[ "${S3_buckets[@]}" =~ "$2" ]]; then
                aws s3api delete-bucket --bucket $2
                echo "Bucket \"$2\" has been deleted."
            else
                if [[ -z "$2" ]]; then
                    echo "error: bucket name was not provided".
                else
                    echo "error: There is no bucket with name \"$2\"."
                fi
            fi
### "-l" and "--list" to list buckets or regions
        elif [[ "$1" == "-l" ]] || [[ "$1" == "--list" ]]; then
### "-l -b" to list buckets
            if [[ "$2" == "-b" ]] || [[ "$2" == "--buckets" ]] || [[ -z "$2" ]]; then
                S3_buckets_list
### "-l -r" to list regions
            elif [[ "$1" == "-r" ]] || [[ "$1" == "--region" ]]; then
                echo "The following is the list of available regions:"
                aws ec2 describe-regions --query 'Regions[].{Name:RegionName}' --output text
            fi
### "-b" and "--bucket" to manage specific buckets
        elif [[ "$1" == "-b" ]] || [[ "$1" == "--bucket" ]]; then
            mapfile -t S3_buckets < <(aws s3 ls | awk '{print $3}')
            if [[ "${S3_buckets[@]}" =~ "$2" ]]; then
### "-b -l" or "-b -f" to list the files in a given bucket
                if [[ "$3" == "-l" ]] || [[ "$3" == "--list" ]] ||
                   [[ "$3" == "-f" ]] || [[ "$3" == "--files" ]]; then
                    echo "The following is the list of files in the bucket \"$2\":"
                    aws s3 ls s3://$2
### "-b -d" to set the directory of a given bucket
                elif [[ "$3" == "-d" ]] || [[ "$3" == "--dir" ]]; then
                    if [[ -d "$4" ]]; then
                        S3_has_dir $2 $4
                        echo "Directory of bucket \"$2\" was set to \"$4\"."
                    elif [[ -f "$4" ]]; then
                        echo "error: \"$4\" is a file."
                    elif [[ -z "$4" ]]; then
                        S3_has_dir $2 $PWD
                        echo "Directory of bucket \"$2\" was set to \"$PWD\"."
                    else
                        echo "The directory \"$4\" does not exists."
                    fi
### "-b -w" to create a website directory for a given bucket
                elif [[ "$3" == "-w" ]] || [[ "$3" == "--website" ]]; then
                    if [[ -d "$4" ]]; then
                        if [[ ! -f $4/policy.json ]]; then
                            S3_website $2 $4
                            echo "A website for the bucket \"$2\" was initialized in the directory \"$4\"." 
                        else
                            echo "error: \"$4\" is already the website dir of some bucket."
                        fi
                    elif [[ -n "$4" ]] && [[ ! -f "$4" ]]; then
                        if [[ ! -f $4/policy.json ]]; then
                            mkdir $4
                            S3_website $2 $4 
                            echo "A website for the bucket \"$2\" was initialized in the directory \"$4\"."
                        else
                            echo "error: \"$4\" is already the website dir of some bucket."
                        fi
                    elif [[ -z "$4" ]]; then
                        if [[ ! -f $PWD/policy.json ]]; then
                            S3_website $2 $PWD 
                            echo "A website for the bucket \"$2\" was initialized in the working directory."
                        else
                            echo "error: \"$PWD\" is already the website dir of some bucket."
                        fi
                    fi
### "-b -ps" to sync files from a local directory to the given bucket
                elif [[ "$3" == "-ps" ]] || [[ "$3" == "--push" ]] || [[ "$3" == "push" ]]; then
                    S3_push $2 $4
### "-b -pl" to sync files from a bucket to its directory
                elif [[ "$3" == "-pl" ]] || [[ "$3" == "--pull" ]] || [[ "$3" == "pull" ]]; then
                    S3_pull $2 $4
                fi
            else
                echo "error: There is no bucket named \"$2\"."
                echo "Try \"aws3 -l\" to get the list of existing buckets." 
            fi
### "-ps" and "--push" to synchronize a given bucket with its directory
        elif [[ "$1" == "-ps" ]] || [[ "$1" == "--push" ]] || [[ "$1" == "push" ]]; then
            S3_push $2 $3
        elif [[ "$1" == "-pl" ]] || [[ "$1" == "--pull" ]] || [[ "$1" == "pull" ]]; then
           S3_pull $2 $3 
### "-r" and "--region" to manage regions
        elif [[ "$1" == "-r" ]] || [[ "$1" == "--region" ]]; then
### "-r -l" to list available regions
            if [[ "$2" == "-l" ]] || [[ "$2" == "--list" ]]; then
              S3_region_list
### "-r -t" to test the regions latency
            elif [[ "$2" == "-t" ]] || [[ "$2" == "--test" ]]; then
                echo "Testing for the region with smallest latency..."
                S3_latency_test
### "-r -s" to set the default region
            elif [[ "$2" == "-s" ]] || [[ "$2" == "--set" ]]; then
                if [[ -n "$3" ]]; then
                    S3_set_region $3
                else
                    echo "error: Please, provide a region."
                fi
            fi
### "--set--region" to set the default region
        elif [[ "$1" == "--set-region" ]]; then
            if [[ -n "$2" ]]; then
                    S3_set_region $2
                else
                    echo "error: Please, provide a region."
                fi
### default error
        else 
            echo "Option not defined for the \"s3()\" function."
        fi
    }
   
