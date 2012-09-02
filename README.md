EVE Skills
=============

EVE Skills is a menu bar app that tracks an EVE Online characters's skill queue.

Features
-------

Some of the features include :

* User notifications when skills are completed or the skill queue is empty.
* Hovering the mouse over the skill queue will display infos about the skill.
* Core Data iCloud sync ready.


Code organization
------------

The app uses Core Data to store all the downloaded data. Bindings are used to build the UI.

The app uses three main controllers (all owned by the app delegate)
* `coreDataController` is responsible for the creation of the persistent store coordinator and owns the main threat managed object context.
* `apiController` is responsible for downloading data using the EVE Online API.
* `userNotificationController` is responsible for the creation and management of all user notifications

The Core Data model has three configs :
* `CloudConfig` contains the API and Character entities.
* `LocalConfig` contains the Corporation, Portrait, Queue and QueueElement entities.
* `SkillConfig` contains the Group and Skill entities.

The goal of having these three configs is to be able to easily add iCloud support. 

All the skill data (`SkillConfig`) is provided with the application in the `skillStore.sqlite` file. The `VGSkillTree` class can download and create the skill store.
