#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("MIT");
MODULE_AUTHOR("Kernel Labs");
MODULE_DESCRIPTION("Hello World kernel module for Yocto");

static int __init hello_init(void)
{
    pr_info("hello: module loaded\n");
    return 0;
}

static void __exit hello_exit(void)
{
    pr_info("hello: module unloaded\n");
}

module_init(hello_init);
module_exit(hello_exit);
