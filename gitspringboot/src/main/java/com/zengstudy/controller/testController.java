package com.zengstudy.controller;

import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/test")
public class testController {

    @PostMapping("/push")
    public void push() {
        System.out.println("这是测试语句");
        System.out.println("linux上正在运行java的jar包");
    }


}
