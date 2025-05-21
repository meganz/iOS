# SOLUTIONS

## Solution For Question1



## Solution For Question2

### Root Cause

When we call the `seekToDestination` function, we may trigger AVPlayer.play multiple times,which may cause the main thread hanged.

 ![2.1](./assets/2.1.png)

![2.2](./assets/2.2.png)

### Solution

Remove the extra call in the notification 







## Solution For Question3

### Root Cause

When Select Mode Enable, it call `reloadPhotos` function, but `reloadPhotos` updates navigation title without judging mode



![3.1](./assets/3.1.png)

![3.2](./assets/3.2.png)

![3.3](./assets/3.3.png)

### Solution

change navigation when mode change

![3.4](./assets/3.4.png)

 

