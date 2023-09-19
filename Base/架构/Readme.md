
# MVC


MVC全名是Model View Controller，是模型(model)－视图(view)－控制器(controller)的缩写，一种软件设计典范，用一种业务逻辑、数据、界面显示分离的方法组织代码，将业务逻辑聚集到一个部件里面，在改进和个性化定制界面及用户交互的同时，不需要重新编写业务逻辑。

> MVC的思想：一句话描述就是Controller负责将Model的数据用View显示出来


### MVC的优点：

1、易用性：与其他几种模式相比最小的代码量。熟悉的人很多，因而即使对于经验不那么丰富的开发者来讲维护起来也较为容易。 

2、有利于组件的重用， view 和model是独立的，可以重用到其它场景


### MVC的缺点：

1、较差的可测试性

2、愈发笨重的 Controller

### Massive Controller的原因：

1、view和ctroller是紧耦合的，所以对于view的构建，不管是用IB还是手写界面，初学者一般是将界面构建的代码放在vc中，甚至在vc的生命周期函数中，这是踏出massive viewController的第一步。

2、网络数据的请求及后续处理：网络请求是一个比较关键的地方，涉及到数据的处理。我们在MVC模式下做个讨论，首先是View，View作为界面实现对象，一般能够用MVC的人不会把网络请求放里面了，这个跳过。接下来是model，一般MVC中model作为模型实体类，用于存放实体信息，执行实体的某些行为，本地数据库的操作，如果把网络请求放到model中执行，网络数据需要异步执行，如果model生命时间比网络数据请求时间长，那还可以，但是一般的服务器返回json数据中包含的实体信息非常多甚至一些无关model的请求，这部分又是一个问题，所以model里做网络显得格格不入，最后只能用vc，这是massive viewController的第二步。

3、响应逻辑：在vc中常常会有对用户事件作出的相应代码以及delegate方法，这部分代码中往往包含着复杂的判断逻辑及数据处理代码，这是massive viewController的第三步。

4、数据源方法：典型的tableView会有datasource方法，其中数cellForRowAtIndexpath最为典型，其中数据展示前的代码也是非常多，massive viewController的第四步。

5、本地数据库操作：不多解释，massive viewController第五步。

6、其它无关vc的代码：其它的比如有点工具性质及其他的代码。于是66大顺，一个massive viewController形成。


# MVVM

## 

[MVVM](https://objccn.io/issue-13-1/)
[MVVM](https://www.clariontech.com/blog/mvvm-in-ios-a-quick-walkthrough)

该模式下，View 和Controller当成一个整体，Controller只负责显示和从UI中获取数据，viewmodel只管从controller中拿数据，VM承担了MVC中controller的获取和缓存数据的任务。

MVVM模块下和响应式编程框架配合最好，完成数据的双向绑定。

### MVVM的优点：

1、方便测试

2、可重用性：可以把一些视图逻辑放在一个 viewModel里面，让很多 view 重用这段视图逻辑

3、低耦合：View 可以独立于Model变化和修改，一个 viewModel 可以绑定到不同的 View 上

4、分工协作独立开发：开发人员可以专注于业务逻辑和数据的开发 viewModel，设计人员可以专注于页面设计

### 缺点：

1、类会增多

2、viewModel会越来越庞大，调用复杂度增加；

3、bug调试成本增加

4、内存占用会增加因为更多的viewmodel
