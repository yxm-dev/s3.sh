About
======

[s3.sh](https://github.com/yxm-dev/s3.sh) is a command line tool, written in `Bash`, based in
[aws/aws-cli](https://github.com/aws/aws-cli), designed to easily manage a configure buckets in AWS S3
service. With it you can create, delete and list buckets, as well as configure them to be publicly accessed,
and to define static websites. 

Installing
======

The tool [s3.sh](https://github.com/yxm-dev/s3.sh) was developed using the package builder
[pkg.sh](https://github.com/yxm-dev/pkg.sh), so that the install/uninstall processes follow their default
steps:

* clone this repository:
    
```bash
    git clone https://github.com/yxm-dev/s3.sh
```

* enter in the install directory:
    
```bash
    cd s3.sh/install
```

* execute the `configure` script with `./configure` and enter the directory `install_dir` where you want to
  install [s3.sh](https://github.com/yxm-dev/s3.sh);
* execute the `install` script with `./install`. Dependencies will be automatically installed.
* delete the `s3.sh` directory if you want:
    
```bash
    cd -
    rm -r s3.sh
```

To uninstall [s3.sh](https://github.com/yxm-dev/s3.sh), enter in the directory `intall_dir/install` and
execute the `uninstall` script:

```bash
    cd install_dir/install
    ./uninstall
```

Alternatively, use the `--uninstall` option.

Dependencies
======

The fundamental dependency is [aws/aws-cli](https://github.com/aws/aws-cli), which in turn depends on `Python 3.7.x`.

Other minor dependencies that probably are already installed in your machine include:

* GNU [grep](https://www.gnu.org/software/grep/)
* GNU [sed](https://www.gnu.org/software/sed/)
* `ping`

Usage
======

```
   usage: s3.sh [options] [arguments] (general case)
   or: s3.sh                       (print this help message)

options:
    -c, --create                      create a bucket
    -d, --delete                      delete a bucket
    -l, --list                        list the existing buckets w/ their directories
        -b, --bucket                  list the existing buckets w/ their directories  
        -r, --region                  list the available regions
    -b, --bucket
        -d, --dir                     set the bucket directory
        -l, --list                    list the existing buckets w/ their directories
        -ps, --push                   push the bucket directory to AWS
        -pl, --pull                   pull the bucket from AWS to its directory
        -w, --website                 create a website directory for the bucket and
                                                                    [make it public
    -r, --region
        -l, --list                    list the available regions
        -t, --test                    test the regions and output that with smallest
                                                                            [latency
        -s, --set                     set the default region
    --set-region                      set the default region
    -h, --help                        display this help message
    -u, --uninstall                   uninstall s3.sh
```

License
=====

This software is licensed under [MIT license](https://github.com/yxm-dev/s3.sh/LICENSE).
