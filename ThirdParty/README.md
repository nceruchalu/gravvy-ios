# Third Party [Submodules](http://git-scm.com/book/en/v2/Git-Tools-Submodules)

This directory contains software from third party vendors.

Each subdirectory contains a 'submodule' subdirectory, which is a
'git submodule' -- i.e. within 'submodule' you're effectively within a
different repo (try 'git branch' or 'git log' within a submodule directory).

Please follow these conventions when adding new third-party vendor software.


## Adding a New Module

1. Add a repository as a submodule, for example the fictional LibExample repo:

   ```git submodule add https://github.com/nceruchalu/LibExample.git```


## Updating a Module
1. Change to the submodule directory: `cd LibExample`
2. Chekout desired branch: `git checkout master`
3. Update: `git pull`

Or if you're a busy person:
```
git submodule foreach git pull
```

## Modules

Brief description of third-party modules. Add a brief description when adding
a new module. Keep list in alphabetical order.


#### [AFNetworking](https://github.com/AFNetworking/AFNetworking)
Networking framework

#### [AMPopTip](https://github.com/andreamazz/AMPopTip)
An animated tooltip

#### [AMScrollingNavbar](https://github.com/andreamazz/AMScrollingNavbar)
Scrollable UINavigationBar that follows the scrolling of a UIScrollView

#### [AWPercentDrivenInteractiveTransition](https://github.com/MrAlek/AWPercentDrivenInteractiveTransition)
Drop-in replacement for UIPercentDrivenInteractiveTransition for use in custom
container view controllers

#### [libPhoneNumber-iOS](http://github.com/iziz/libPhoneNumber-iOS)
iOS port from libphonenumber (Google's phone number handling library)

#### [SCRecorder](https://github.com/rFlex/SCRecorder)
iOS camera engine with tap to record functionality

#### [SDWebImage](https://github.com/rs/SDWebImage)
Asynchronous image downloader with cache support with an UIImageView category
