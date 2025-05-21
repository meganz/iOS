# SOLUTIONS

## Solution For Question1



## Solution For Question2



## Solution For Question3

### Root Cause

When Select Mode Enable, it call `reloadPhotos` function, but `reloadPhotos` updates navigation title without judging mode



![3.1](./assets/3.1.png)

![3.2](./assets/3.2.png)

![3.3](./assets/3.3.png)

### Solution

change navigation when mode change

![3.4](./assets/3.4.png)

 

