import List "mo:base/List";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Time "mo:base/Time"

actor {
    public type Message = {
        author: Text;
        text: Text;
        time: Time.Time;
    };

    public type Microblog = actor {
        follow: shared(Principal) -> async (); //添加关注对象
        follows: shared query () -> async [Principal]; //返回关注列表
        post: shared (Text, Text) -> async (); //发布新消息
        posts: shared query (Time.Time) -> async [Message]; //返回所有发布的消息
        timeline: shared (Time.Time) -> async [Message]; //返回所有关注对象发布的消息
        set_name: shared(Text) -> async(); //设置作者
        get_name: shared query () -> async ?Text; //返回作者
    };

    var name: Text = "";

    public shared func set_name(new_name: Text) : async () {
        name := new_name;
    };

    public shared query func get_name() : async ?Text {
        ?name;
    };

    var followed: List.List<Principal> = List.nil();

    public shared func follow(id: Principal) : async () {
        followed := List.push(id, followed);
    }; 

    public shared query func follows() : async [Principal] {
        List.toArray(followed);
    };

    var messages : List.List<Message> = List.nil();

    public shared func post(pwd: Text, text: Text) : async () {
        assert(pwd == "123456");
        let time = Time.now();
        let author = name;
        messages := List.push({author; text; time}, messages);
    };

    public shared query func posts(since: Time.Time) : async [Message] {
        //List.toArray(messages);
        List.toArray(List.filter<Message>(messages, func({time}) = time >= since));
    };

    public shared func timeline(since: Time.Time) : async [Message] {
        var all : List.List<Message> = List.nil();

        for(id in Iter.fromList(followed)) {
            let canister : Microblog = actor(Principal.toText(id));
            let msgs: [Message] = await canister.posts(since);
            all := List.append<Message>(List.fromArray(msgs), all);
        };

        List.toArray(all);
    };
};
