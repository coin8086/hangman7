import java.util.Scanner;
import java.io.File;
import java.io.IOException;
import java.util.Set;
import java.util.HashSet;
import java.util.List;
import java.util.LinkedList;
import java.util.Random;
import java.util.Calendar;

class RandomWords {
  public static void main(String[] args) {
    if (args.length < 1) {
      System.err.println("A number of random words is expected but missing.");
      System.exit(-1);
    }

    String file = System.getenv("hangman_dict");
    if (file == null)
      file = "words.txt";

    // Read in dictionary file
    List<String> dict = new LinkedList<String>();
    try {
      Scanner s = new Scanner(new File(file));
      while (s.hasNext()) {
        String word = s.next();
        if (word.length() > 0)
          dict.add(word.toUpperCase());
      }
    }
    catch (IOException e) {
      System.err.println(String.format("Cannot open dictionary file '%s' for reading!", file));
      System.exit(-1);
    }

    int count = 0;
    try {
      count = Integer.parseInt(args[0]);
    }
    catch(NumberFormatException e) {
      System.err.println(String.format("%s is not a number!", args[0]));
      System.exit(-1);
    }

    if (count < 1 || count > dict.size()) {
      System.err.println(String.format("%s is out of [1, %d]!", args[0], dict.size()));
      System.exit(-1);
    }

    // Produce random words in dictionary
    int size = dict.size();
    Set<Integer> included = new HashSet<Integer>();
    Random rand = new Random(Calendar.getInstance().getTime().getTime());

    while (count > 0) {
      int r = (rand.nextInt(size) * 10 + rand.nextInt(size) + (rand.nextInt(size) / (rand.nextInt(size) + 1))) % size;
      if (included.add(r)) {
        System.out.println(dict.get(r));
        count--;
      }
    }

  }

}
