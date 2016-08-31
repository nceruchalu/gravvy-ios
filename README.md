# Gravvy

## About Gravvy
|         |                                                        |
| ------- | ------------------------------------------------------ |
| Author  | Nnoduka Eruchalu                                       |
| Date    | 05/09/2014                                             |
| Website | [http://gravvy.nnoduka.com](http://gravvy.nnoduka.com) |


## Software Description
### 3rd-party Objective-C Modules

#### [Git Submodules](http://git-scm.com/book/en/v2/Git-Tools-Submodules)
* [AFNetworking](https://github.com/AFNetworking/AFNetworking)
* [AWPercentDrivenInteractiveTransition](https://github.com/MrAlek/AWPercentDrivenInteractiveTransition)
* [libPhoneNumber-iOS](http://github.com/iziz/libPhoneNumber-iOS)
* [SCRecorder](https://github.com/rFlex/SCRecorder)
* [SDWebImage](https://github.com/rs/SDWebImage)
* [AMScrollingNavbar](https://github.com/andreamazz/AMScrollingNavbar)
* [AMPopTip](https://github.com/andreamazz/AMPopTip)

#### Other Libraries
* [ALAlertBanner](https://github.com/alobi/ALAlertBanner): Using modified version of this.
* [Sheriff](https://github.com/gemr/sheriff): Using modified version of this.
* [TGCameraViewController](https://github.com/tdginternet/TGCameraViewController): Camera View Controller is based on this.
* [Sound Switch](http://sharkfood.com/content/Developers/content/Sound%20Switch/)

### Working with Git Submodules
* All submodules can be found in the `ThirdParty/` directory
* Clone this project with: `git clone --recursive <git repo>`
* Update submodules with `git submodule update --remote <Module-Name>`

### Core Data Design Decisions
#### Denormalization
Goal is to avoid unnecessary joins (i.e. performance optimization)
So the idea here is to store relationship meta information on source such as:
* count
* existence
* aggregate values

This drove the decision to have an `unreadMessageCount` attribute on the 
`BBTContactConversation` NSManagedObject.

#### Normalization
Goal is to prevent duplication of data.
So the idea here is to separate unlike things hence the two NSManagedObjects:
`GRVVideo` and `GRVClip` linked with the following relationships
* clip.video <<--> video.clips
* clip.videoUsingAsLeadClip <--> video.leadClip

#### Fetch Batch Size
* On an iPhone only 10 rows are visible 
* So doesn't make sense to fetch every possible object
* Hence chose to use a fetch batch size of 20

#### Relationship faulting
* There are some cases where the master table shows related data, so need the related data *now*.
* In these cases prefetch to avoid faulting individually
  ** so for videos TVC use `[request setRelationshipKeypathsForPrefetching: @["owner"]]`

#### Core Data Migration
[Lightweight migrations][lightweight-migrations-ref] are relatively easy and 
can be peformed with some simple [steps][migrations-how-to]

* Select **Gravvy.xcdatamodeld** in Xcode
* From the menu select **Editor > Add Model Version...**
* Leave the version name as is and then click **Finish**.
* Select **Gravvy.xcdatamodeld** again (not _Gravvy.xcdatamodel_, that's the old
  version) and this time in the File inspector (**View > Utilities > Show File Inspector**)
* In the **Model Version** section, select the new version name for _Current_.
* You should now see a little green circle with a white checkmark badge on
  the new model version in the Project Navigator (**View > Navigators > Show Project Navigator**).

[lightweight-migrations-ref]: https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/vmLightweightMigration.html#//apple_ref/doc/uid/TP40004399-CH4-SW1
[migrations-how-to]: http://www.raywenderlich.com/27657/how-to-perform-a-lightweight-core-data-migration

### Compiling
#### KeychainItemWrapper
Since the project uses ARC and the KeychainItemWrapper class is not ARC 
compliant you have to inform the compiler that this class is not an ARC
compliant class. You can do this by selecting your target and select the **Build
Phases** tab and add the `-fno-objc-arc` compiler flag.