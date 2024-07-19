import java.sql.*;

public class OjdbcConnect {
    public static void main(String[] args) {
        String url = "jdbc:oracle:thin:@192.168.24.194:1521/CZD01T";
				// SIDの場合は1521:orcl
        String user = "NISHI";
        String password = "password";

        try (Connection connection = DriverManager.getConnection(url, user, password)) {
            if (connection != null && !connection.isClosed()) {
                System.out.println("接続に成功しました。");
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
    }
}


ターミナルで以下のとおりコンパイル

javac -classpath /path/to/ojdbc11.jar /path/to/OjdbcConnect.java

ファイルOjdbcConnect.classが生成される

ターミナルで以下のとおり実行し、"接続に成功しました。"が返ればOK

java -classpath .:/path/to/ojdbc11.jar OjdbcConnect