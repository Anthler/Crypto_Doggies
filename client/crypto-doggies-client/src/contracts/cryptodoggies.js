import web3 from "../web3/web3";
import CDABI from "./contracts/CryptoDoggies.json";

//const CDAddress = "0xd0cd69de4f1c7b56e06af535cf27730670bad8b9";
const CDAddress = "0x264629119625a11d8113ccb29e1f38388212895a";

const instance = new web3.eth.Contract(CDABI, CDAddress);
//console.log(instance.options.address);

//console.log("methods ", instance.methods);
//   .name()
//   .then(value => {
//     console.log(value);
//   })
//   .catch(err => {
//     console.log(err);
//   });

export default instance;
