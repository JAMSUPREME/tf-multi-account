package jam.helloworld;

import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
public class HelloController {

  // TODO: add an env variable here so we can tell if it's dev,prod,qa
  @RequestMapping("/")
  public String index() {
    return "Greetings!";
  }

}