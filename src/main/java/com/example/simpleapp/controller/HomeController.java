package com.example.simpleapp.controller;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class HomeController {

    @GetMapping("/")
    public String home(Model model) {
        model.addAttribute("message", "Welcome to Simple Spring Boot Web App!");
        return "index";
    }

    @GetMapping("/api/hello")
    @ResponseBody
    public String hello(@RequestParam(defaultValue = "World") String name) {
        return "Hello, " + name + "!";
    }

    @GetMapping("/api/info")
    @ResponseBody
    public AppInfo getInfo() {
        return new AppInfo("Simple Spring Boot App", "1.0.0", "A simple web application");
    }

    // Inner class for JSON response
    public static class AppInfo {
        private String name;
        private String version;
        private String description;

        public AppInfo(String name, String version, String description) {
            this.name = name;
            this.version = version;
            this.description = description;
        }

        public String getName() {
            return name;
        }

        public void setName(String name) {
            this.name = name;
        }

        public String getVersion() {
            return version;
        }

        public void setVersion(String version) {
            this.version = version;
        }

        public String getDescription() {
            return description;
        }

        public void setDescription(String description) {
            this.description = description;
        }
    }
}

// Made with Bob
